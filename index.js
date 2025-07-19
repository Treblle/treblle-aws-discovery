// AWS SDK v3 imports (available in Node.js 22.x runtime)
const { APIGatewayClient, GetRestApisCommand, GetStagesCommand } = require('@aws-sdk/client-api-gateway');
const { ApiGatewayV2Client, GetApisCommand, GetStagesCommand: GetStagesV2Command } = require('@aws-sdk/client-apigatewayv2');
const { STSClient, GetCallerIdentityCommand } = require('@aws-sdk/client-sts');
const https = require('https');

// Create HTTPS agent with connection pooling
const httpsAgent = new https.Agent({
    keepAlive: true,
    maxSockets: 50,
    maxFreeSockets: 10,
    timeout: 60000,
    freeSocketTimeout: 30000
});

// Configuration
const BATCH_SIZE = 50; // Number of APIs to send per batch
const TREBLLE_SDK_TOKEN = process.env.TREBLLE_SDK_TOKEN;
const SCAN_REGIONS = process.env.SCAN_REGIONS;

// Initialize AWS clients
const stsClient = new STSClient({});

exports.handler = async (event) => {
    console.log('Starting API Gateway discovery...');
    
    // Validate required environment variables
    if (!TREBLLE_SDK_TOKEN) {
        console.error('TREBLLE_SDK_TOKEN environment variable is required');
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: 'Configuration error',
                message: 'TREBLLE_SDK_TOKEN environment variable is required'
            })
        };
    }
    
    try {

        // Validate environment variables  
        if (!SCAN_REGIONS) {
            console.error('SCAN_REGIONS environment variable is required');
            return {
                statusCode: 500,
                body: JSON.stringify({
                    error: 'Configuration error',
                    message: 'SCAN_REGIONS environment variable is required'
                })
            };
        }
        
        // Parse and validate regions from comma-separated string
        const regions = SCAN_REGIONS.split(',').map(region => region.trim()).filter(region => region.length > 0);
        const validRegions = validateRegions(regions);
        if (validRegions.length === 0) {
            console.error('No valid regions found in SCAN_REGIONS');
            return {
                statusCode: 500,
                body: JSON.stringify({
                    error: 'Configuration error',
                    message: 'No valid regions found in SCAN_REGIONS'
                })
            };
        }
        // Get current account ID (the account where Lambda is deployed)
        const currentAccountId = await getCurrentAccountId();
        console.log(`Will scan current account ${currentAccountId} in ${validRegions.length} regions: ${validRegions.join(', ')}`);
        
        // Use default credentials since we're scanning the current account
        const credentials = null;
        
        // Scan all regions in parallel
        console.log(`Starting parallel scan of ${validRegions.length} regions...`);
        const scanPromises = validRegions.map(region => 
            scanRegion(currentAccountId, region, credentials)
        );
        
        const results = await Promise.allSettled(scanPromises);
        
        // Process results
        const allApis = [];
        let totalApis = 0;
        let successfulRegions = 0;
        let failedRegions = 0;
        
        results.forEach((result, index) => {
            const region = validRegions[index];
            if (result.status === 'fulfilled') {
                const apis = result.value;
                allApis.push(...apis);
                totalApis += apis.length;
                successfulRegions++;
                console.log(`✓ Found ${apis.length} APIs in ${currentAccountId}/${region}`);
            } else {
                failedRegions++;
                console.error(`✗ Error scanning ${currentAccountId}/${region}:`, result.reason.message);
            }
        });
        
        console.log(`Scan complete: ${successfulRegions} successful, ${failedRegions} failed regions`);
        
        console.log(`Total APIs discovered: ${totalApis}`);
        
        // Send APIs in batches to discovery endpoint
        if (allApis.length > 0) {
            await sendApisInBatches(allApis);
        }
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'API discovery completed successfully',
                totalApis: totalApis,
                targetAccount: currentAccountId,
                regionsScanned: successfulRegions,
                regionsRequested: validRegions.length,
                regionsFailed: failedRegions,
                regions: validRegions
            })
        };
        
    } catch (error) {
        console.error('Error in API discovery:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: 'API discovery failed',
                message: error.message
            })
        };
    }
};

// Validate AWS regions
function validateRegions(regions) {
    const validAwsRegions = [
        'us-east-1', 'us-east-2', 'us-west-1', 'us-west-2',
        'eu-west-1', 'eu-west-2', 'eu-west-3', 'eu-central-1', 'eu-north-1', 'eu-south-1',
        'ap-southeast-1', 'ap-southeast-2', 'ap-southeast-3', 'ap-northeast-1', 'ap-northeast-2', 'ap-northeast-3', 'ap-south-1', 'ap-east-1',
        'ca-central-1', 'sa-east-1', 'af-south-1', 'me-south-1'
    ];
    
    const validRegions = regions.filter(region => validAwsRegions.includes(region));
    const invalidRegions = regions.filter(region => !validAwsRegions.includes(region));
    
    if (invalidRegions.length > 0) {
        console.warn(`Invalid regions ignored: ${invalidRegions.join(', ')}`);
    }
    
    return validRegions;
}

// Scan a single region for APIs
async function scanRegion(accountId, region, credentials) {
    try {
        console.log(`Scanning account ${accountId} in region ${region}...`);
        return await discoverApisInAccount(accountId, region, credentials);
    } catch (error) {
        console.error(`Error scanning ${accountId}/${region}:`, error.message);
        throw error;
    }
}

// Get current account ID
async function getCurrentAccountId() {
    try {
        const command = new GetCallerIdentityCommand({});
        const result = await stsClient.send(command);
        return result.Account;
    } catch (error) {
        console.error('Error getting current account ID:', error);
        throw error;
    }
}


// Create API Gateway clients for a region
function createApiGatewayClients(region, credentials) {
    const clientConfig = {
        region: region
    };
    
    if (credentials) {
        clientConfig.credentials = credentials;
    }
    
    return {
        apiGatewayClient: new APIGatewayClient(clientConfig),
        apiGatewayV2Client: new ApiGatewayV2Client(clientConfig)
    };
}

// Discover APIs in a specific account and region
async function discoverApisInAccount(accountId, region, credentials) {
    const apis = [];
    
    // Create clients once for this region
    const { apiGatewayClient, apiGatewayV2Client } = createApiGatewayClients(region, credentials);
    
    try {
        // Discover REST APIs and HTTP APIs in parallel
        const [restApis, httpApis] = await Promise.all([
            discoverRestApis(apiGatewayClient, accountId, region),
            discoverHttpApis(apiGatewayV2Client, accountId, region)
        ]);
        
        apis.push(...restApis, ...httpApis);
        
    } catch (error) {
        console.error(`Error discovering APIs in ${accountId}/${region}:`, error.message);
        throw error;
    }
    
    return apis;
}

// Discover REST APIs
async function discoverRestApis(apiGatewayClient, accountId, region) {
    const apis = [];
    let position = null;
    
    do {
        try {
            const command = new GetRestApisCommand({
                limit: 500,
                position: position || undefined
            });
            
            const result = await apiGatewayClient.send(command);
            
            for (const api of result.items || []) {
                // Get stages for this API
                const stages = await getRestApiStages(apiGatewayClient, api.id);
                
                // Build endpoint URL
                const endpoint = `https://${api.id}.execute-api.${region}.amazonaws.com`;
                
                apis.push({
                    accountId: accountId,
                    region: region,
                    apiId: api.id,
                    apiName: api.name,
                    apiType: 'REST',
                    stages: stages,
                    endpoint: endpoint
                });
            }
            
            position = result.position;
            
        } catch (error) {
            console.error(`Error getting REST APIs:`, error.message);
            break;
        }
        
    } while (position);
    
    return apis;
}

// Discover HTTP APIs
async function discoverHttpApis(apiGatewayV2Client, accountId, region) {
    const apis = [];
    let nextToken = null;
    
    do {
        try {
            const command = new GetApisCommand({
                MaxResults: '500',
                NextToken: nextToken || undefined
            });
            
            const result = await apiGatewayV2Client.send(command);
            
            for (const api of result.Items || []) {
                // Get stages for this API
                const stages = await getHttpApiStages(apiGatewayV2Client, api.ApiId);
                
                // Build endpoint URL
                const endpoint = `https://${api.ApiId}.execute-api.${region}.amazonaws.com`;
                
                apis.push({
                    accountId: accountId,
                    region: region,
                    apiId: api.ApiId,
                    apiName: api.Name,
                    apiType: 'HTTP',
                    stages: stages,
                    endpoint: endpoint
                });
            }
            
            nextToken = result.NextToken;
            
        } catch (error) {
            console.error(`Error getting HTTP APIs:`, error.message);
            break;
        }
        
    } while (nextToken);
    
    return apis;
}

// Get stages for REST API
async function getRestApiStages(apiGatewayClient, apiId) {
    try {
        const command = new GetStagesCommand({
            restApiId: apiId
        });
        
        const result = await apiGatewayClient.send(command);
        return (result.item || []).map(stage => stage.stageName);
    } catch (error) {
        console.error(`Error getting stages for REST API ${apiId}:`, error.message);
        return [];
    }
}

// Get stages for HTTP API
async function getHttpApiStages(apiGatewayV2Client, apiId) {
    try {
        const command = new GetStagesV2Command({
            ApiId: apiId
        });
        
        const result = await apiGatewayV2Client.send(command);
        return (result.Items || []).map(stage => stage.StageName);
    } catch (error) {
        console.error(`Error getting stages for HTTP API ${apiId}:`, error.message);
        return [];
    }
}

// Send APIs to discovery endpoint in batches
async function sendApisInBatches(apis) {
    const batches = [];
    
    // Split APIs into batches
    for (let i = 0; i < apis.length; i += BATCH_SIZE) {
        batches.push(apis.slice(i, i + BATCH_SIZE));
    }
    
    console.log(`Sending ${apis.length} APIs in ${batches.length} batches`);
    
    // Send each batch
    for (let i = 0; i < batches.length; i++) {
        const batch = batches[i];
        console.log(`Sending batch ${i + 1}/${batches.length} with ${batch.length} APIs`);
        
        try {
            await sendApisBatch(batch);
            console.log(`Successfully sent batch ${i + 1}`);
        } catch (error) {
            console.error(`Error sending batch ${i + 1}:`, error.message);
            // Continue with other batches
        }
        
        // Small delay between batches to avoid overwhelming the endpoint
        if (i < batches.length - 1) {
            await new Promise(resolve => setTimeout(resolve, 100));
        }
    }
}

// Send a single batch of APIs
async function sendApisBatch(apis) {
    return new Promise((resolve, reject) => {
        const postData = JSON.stringify(apis);
        
        const options = {
            hostname: 'autodiscovery.treblle.com',
            port: 443,
            path: '/api/v1/aws',
            method: 'POST',
            agent: httpsAgent,
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData),
                'x-api-key': TREBLLE_SDK_TOKEN,
                'User-Agent': 'Treblle-AWS-Discovery/1.0'
            }
        };
        
        const req = https.request(options, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve(data);
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        });
        
        req.on('error', (error) => {
            reject(error);
        });
        
        req.write(postData);
        req.end();
    });
}