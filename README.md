# Treblle AWS API Gateway Discovery

Automatically discover and monitor API Gateway APIs across your AWS account with Treblle's intelligent discovery service.

## Overview

This repository contains a serverless AWS Lambda function that:

- 🔍 **Automatically discovers** all REST and HTTP APIs in your AWS account
- 🌍 **Scans multiple regions** in parallel for fast discovery
- 🏗️ **Deploys via CloudFormation** with a single command
- 📊 **Sends API data** to Treblle for monitoring and analytics
- ⚡ **Highly optimized** with connection pooling and parallel processing
- 🔄 **Runs on schedule** (default: every 24 hours)

### Key Features

- **Single-account discovery** - Automatically detects and scans the AWS account where deployed
- **Multi-region support** - Configure which AWS regions to scan
- **Performance optimized** - Parallel region scanning, connection pooling, SDK client reuse
- **Region validation** - Only scans valid AWS regions, warns about invalid ones
- **Comprehensive logging** - Detailed success/failure reporting per region
- **Cost-efficient** - Optimized memory usage (256MB) and execution time

## Prerequisites

- AWS account with API Gateway APIs to discover
- [Treblle SDK Token](https://treblle.com) for API monitoring
- AWS CLI installed (for CLI deployment) or access to AWS Console

## Installation

### Option 1: AWS CLI Deployment (Recommended)

1. **Clone this repository**
   ```bash
   git clone <repository-url>
   cd treblle-aws-discovery
   ```

2. **Deploy the CloudFormation stack**
   ```bash
   aws cloudformation deploy \
     --template-file cloudformation.yaml \
     --stack-name treblle-api-discovery \
     --parameter-overrides \
       TreblleSDKToken=YOUR_TREBLLE_SDK_TOKEN \
       RegionList=us-east-1,us-west-2,eu-west-1 \
     --capabilities CAPABILITY_NAMED_IAM
   ```

3. **Test the function** (optional)
   ```bash
   aws lambda invoke \
     --function-name treblle-api-gateway-discovery \
     response.json
   
   cat response.json
   ```

### Option 2: AWS Console Deployment

1. **Download the CloudFormation template**
   - Download the `cloudformation.yaml` file from this repository

2. **Open AWS CloudFormation Console**
   - Go to [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/)
   - Select the AWS region where you want to deploy the discovery function

3. **Create a new stack**
   - Click **"Create stack"** → **"With new resources (standard)"**
   - Choose **"Upload a template file"**
   - Click **"Choose file"** and select the downloaded `cloudformation.yaml`
   - Click **"Next"**

4. **Configure stack parameters**
   - **Stack name**: `treblle-api-discovery` (or your preferred name)
   - **TreblleSDKToken**: Your Treblle SDK token
   - **RegionList**: Comma-separated list of regions to scan (e.g., `us-east-1,us-west-2,eu-west-1`)
   - **ScheduleExpression**: How often to run discovery (default: `rate(24 hours)`)
   - Click **"Next"**

5. **Configure stack options** (optional)
   - Add tags if desired
   - Configure advanced options if needed
   - Click **"Next"**

6. **Review and create**
   - Review your configuration
   - Check **"I acknowledge that AWS CloudFormation might create IAM resources with custom names"**
   - Click **"Submit"**

7. **Wait for deployment**
   - The stack will take 2-3 minutes to deploy
   - Status will change to `CREATE_COMPLETE` when finished

## Configuration Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `TreblleSDKToken` | Your Treblle SDK token for API monitoring | *Required* | `tre_sk_...` |
| `RegionList` | Comma-separated list of AWS regions to scan | `us-east-1,us-west-2,eu-west-1` | `us-east-1,eu-central-1` |
| `ScheduleExpression` | How often to run discovery | `rate(24 hours)` | `cron(0 9 * * ? *)` |

### Supported AWS Regions

The function validates and supports these AWS regions:
- **US**: `us-east-1`, `us-east-2`, `us-west-1`, `us-west-2`
- **Europe**: `eu-west-1`, `eu-west-2`, `eu-west-3`, `eu-central-1`, `eu-north-1`, `eu-south-1`
- **Asia Pacific**: `ap-southeast-1`, `ap-southeast-2`, `ap-southeast-3`, `ap-northeast-1`, `ap-northeast-2`, `ap-northeast-3`, `ap-south-1`, `ap-east-1`
- **Other**: `ca-central-1`, `sa-east-1`, `af-south-1`, `me-south-1`

## Multiple AWS Accounts

To monitor multiple AWS accounts, deploy this CloudFormation stack in each target account:

```bash
# Account 1
aws cloudformation deploy \
  --template-file cloudformation.yaml \
  --stack-name treblle-api-discovery \
  --parameter-overrides TreblleSDKToken=TOKEN RegionList=us-east-1,us-west-2 \
  --capabilities CAPABILITY_NAMED_IAM

# Account 2 (switch AWS profile/credentials)
aws cloudformation deploy \
  --template-file cloudformation.yaml \
  --stack-name treblle-api-discovery \
  --parameter-overrides TreblleSDKToken=TOKEN RegionList=eu-west-1,eu-central-1 \
  --capabilities CAPABILITY_NAMED_IAM
```

## How It Works

1. **Scheduled Execution**: EventBridge triggers the Lambda function on your defined schedule
2. **Account Detection**: Function automatically detects the current AWS account ID
3. **Region Validation**: Validates and filters the configured regions list
4. **Parallel Scanning**: Scans all regions simultaneously for optimal performance
5. **API Discovery**: Discovers both REST APIs and HTTP APIs in each region
6. **Data Collection**: Collects API metadata including stages, endpoints, and configuration
7. **Batch Processing**: Sends discovered APIs to Treblle in optimized batches
8. **Monitoring**: Treblle processes and monitors your APIs for insights and analytics

## Performance & Optimization

This function is highly optimized for performance and cost:

- **Parallel Processing**: All regions scanned simultaneously
- **Connection Pooling**: HTTPS connections reused across requests
- **SDK Client Reuse**: AWS SDK clients created once per region
- **Memory Optimized**: Uses 256MB memory (based on actual usage analysis)
- **Timeout Optimized**: 10-minute timeout for comprehensive scanning
- **Batch Processing**: APIs sent in batches of 50 for efficient network usage

## Monitoring & Logs

View function logs in CloudWatch:

```bash
aws logs tail /aws/lambda/treblle-api-gateway-discovery --follow
```

Or via AWS Console:
- Go to CloudWatch → Log groups → `/aws/lambda/treblle-api-gateway-discovery`

## Troubleshooting

### Common Issues

**Function times out**
- Increase timeout in CloudFormation template if you have many APIs
- Check if regions are valid and accessible

**No APIs discovered**
- Verify the function has proper IAM permissions
- Ensure API Gateway APIs exist in the specified regions
- Check CloudWatch logs for detailed error messages

**Invalid regions error**
- Verify region names are correct and supported
- Check the supported regions list above

### Manual Testing

Test the function manually:

```bash
aws lambda invoke \
  --function-name treblle-api-gateway-discovery \
  --payload '{}' \
  response.json && cat response.json
```

## Cleanup

To remove the discovery function:

```bash
aws cloudformation delete-stack --stack-name treblle-api-discovery
```

Or delete via AWS Console → CloudFormation → Select stack → Delete

## Security

### AWS Resources Created

This CloudFormation stack creates the following AWS resources:

#### 1. **IAM Role** - `TreblleDiscoveryLambdaRole`
- **Type:** `AWS::IAM::Role`
- **Purpose:** Lambda execution role with account-wide API Gateway read access
- **Attached Policies:**
  - `arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole`
  - Custom inline policy: `TreblleDiscoveryPolicy`

#### 2. **Lambda Function** - `treblle-api-gateway-discovery`
- **Type:** `AWS::Lambda::Function`
- **Purpose:** API Gateway discovery and external data transmission
- **Runtime:** `nodejs22.x` on `arm64` architecture
- **Network Access:** Makes HTTPS calls to `autodiscovery.treblle.com`

#### 3. **EventBridge Rule** - `treblle-api-gateway-discovery-schedule`
- **Type:** `AWS::Events::Rule`
- **Purpose:** Scheduled trigger (default: every 24 hours)
- **Permissions:** Can only invoke the specific Lambda function

#### 4. **Lambda Permission** - `LambdaInvokePermission`
- **Type:** `AWS::Lambda::Permission`
- **Purpose:** Allows EventBridge to invoke the Lambda function

#### 5. **CloudWatch Log Group** - `/aws/lambda/treblle-api-gateway-discovery`
- **Type:** `AWS::Logs::LogGroup`
- **Purpose:** Function logs (30-day retention)

### Required Permissions for Deployment

#### CloudFormation Deployment Permissions
- `iam:CreateRole` - Create the Lambda execution role
- `iam:DeleteRole` - Delete role during stack deletion
- `iam:GetRole` - Read existing role configuration
- `iam:AttachRolePolicy` - Attach AWS managed policies to role
- `iam:PutRolePolicy` - Create inline policies on role
- `iam:PassRole` - Allow CloudFormation to assign role to Lambda
- `lambda:CreateFunction` - Create the Lambda function
- `lambda:UpdateFunctionCode` - Update function code during stack updates
- `lambda:UpdateFunctionConfiguration` - Modify function settings
- `lambda:AddPermission` - Grant EventBridge invoke permissions
- `events:PutRule` - Create EventBridge scheduled rule
- `events:PutTargets` - Configure Lambda as rule target
- `logs:CreateLogGroup` - Create CloudWatch log group
- `logs:PutRetentionPolicy` - Set 30-day log retention
- `cloudformation:CreateStack` - Create the CloudFormation stack
- `cloudformation:UpdateStack` - Update stack configuration
- `cloudformation:DescribeStacks` - Read stack status and outputs

### Specific API Gateway Actions

#### REST API (v1) Access
- `apigateway:GetRestApis` - List all REST APIs
- `apigateway:GetStages` - Read stage configurations
- `apigateway:GetDeployments` - Access deployment history
- `apigateway:GetResources` - Read API resources
- `apigateway:GetMethod` - Access method configurations

#### HTTP API (v2) Access
- `apigatewayv2:GetApis` - List all HTTP APIs
- `apigatewayv2:GetStages` - Read stage configurations
- `apigatewayv2:GetRoutes` - Access route definitions
- `apigatewayv2:GetIntegrations` - Read integration configs

## Support

- **Treblle Documentation**: [https://docs.treblle.com](https://docs.treblle.com)
- **Treblle Support**: [https://treblle.com/support](https://treblle.com/support)
- **AWS Lambda Documentation**: [https://docs.aws.amazon.com/lambda/](https://docs.aws.amazon.com/lambda/)

## License

This project is licensed under the MIT License - see the LICENSE file for details.