# Instance Scheduler AWS

Guide I used to set this:
1. https://aws.amazon.com/solutions/implementations/instance-scheduler-on-aws/
2. https://medium.com/zen-enterprise/how-to-implement-aws-instance-scheduler-for-cross-account-cost-savings-7f6c27b3b298

## What was needed

We needed a way to manage all EC2 instances and RDS DBs and define inactivity period for them. This needed to be orchestrated on Organization level and push to all accounts managed by the Organization.

## Solution

Current CF templates offered by AWS were used and the whole solution is in TF code.
The solution is split on 2 separate tasks:
Task 1: Create in HUB (Management Account where the Organization is set) AWSInstanceScheduler and assign Schedules for all instances.
Task 2: Create on Remote Account permissions to execute schedules from the HUB.

Folder structure:
-- HUB
   |-- 00_provider.tf
   |-- AWSInstScheduleCFStackSandBoxTFTest.tf
   |-- modules
   |   `-- HubScheduler
   |       |-- files
   |       |   |-- instance-scheduler-on-aws.template
   |       |   |-- schedules.yml
   |       |   `-- schedules_orig.yml
   |       |-- instance_schedule_cf.tf
   |       `-- varibles.tf
   |-- terraform.tfstate
   `-- terraform.tfstate.backup
-- README.md
-- Remote
   |-- 00_provider.tf
   |-- AWSInstScheduleCFStackSandBoxTFTestRemote.tf
   |-- modules
   |   `-- RemoteScheduler
   |       |-- files
   |       |   `-- aws-instance-scheduler-remote.template
   |       |-- instance_schedules_cf.tf
   |       `-- variable.tf
   |-- terraform.tfstate
   `-- terraform.tfstate.backup
### HUB config

Main code is set in instance_schedule_cf.tf and all the variables are pasted from AWSInstScheduleCFStackSandBoxTFTest.tf.

If any changes are needed how the Scheduler works please change this file and update the config
AWSInstScheduleCFStackSandBoxTFTest.tf
```
module "AWSInstanceSchedulerHub" {
  source = "./modules/HubScheduler"

  Name                        = "AWSInstanceSchedulerHub"   ### This is the CF Name. Needs to be uniq.
  NameSchedule                = "AWSInstanceSchedules"      ### Name of the Schedule.
  CreateRdsSnapshot           = "No"
  DefaultTimezone             = "UTC"
  EnableSSMMaintenanceWindows = "Yes"
  LogRetentionDays            = 30
  MemorySize                  = 1536
  Namespace                   = "MainAWSInstanceSchedulerHub"    ### Name of the Namespace and this is used if we need to create in a way horizontal scaling policies. The other way is to use different periods.
  Principals                  = "o-isxlj23fyq"    ### This is the Organization ID.
  Regions                     = "us-east-1,us-east-2,us-west-1,us-west-2,ap-south-1,ap-northeast-3,ap-northeast-2,ap-southeast-1,ap-southeast-2,ap-northeast-1,ca-central-1,eu-central-1,eu-west-1,eu-west-2,eu-west-3,eu-north-1,sa-east-1"    ### all regions
  ScheduledServices           = "Both"
  ScheduleLambdaAccount       = "Yes"
  ScheduleRdsClusters         = "Yes"
  SchedulerFrequency          = 5
  SchedulingActive            = "Yes"
  StartedTags                 = "MonitoringEnabled=True,ScheduleStartMsg=Started on {day}/{month}/{year} at {hour}:{minute} {timezone}"   ## this is agreed on the team and creates tags for Monitoring. We need that.
  StoppedTags                 = "MonitoringEnabled=False,ScheduleStopMsg=Stopped on {day}/{month}/{year} at {hour}:{minute} {timezone}"
  TagName                     = "Schedule"
  Trace                       = "Yes"
  UseCloudWatchMetrics        = "Yes"
  UsingAWSOrganizations       = "Yes"

}
```
Resources that are created and on change in the module we trigger this code:
instance_schedule_cf.tf
```
locals {
  vars = {
    ServiceInstanceScheduleServiceTokenARN = aws_cloudformation_stack.stack.outputs.ServiceInstanceScheduleServiceToken
  }
}



resource "aws_cloudformation_stack" "stack" {
  name         = var.Name
  capabilities = ["CAPABILITY_IAM"]
  parameters = {
    CreateRdsSnapshot           = var.CreateRdsSnapshot
    DefaultTimezone             = var.DefaultTimezone
    EnableSSMMaintenanceWindows = var.EnableSSMMaintenanceWindows
    LogRetentionDays            = var.LogRetentionDays
    MemorySize                  = var.MemorySize
    Namespace                   = var.Namespace
    Principals                  = var.Principals
    Regions                     = var.Regions
    ScheduledServices           = var.ScheduledServices
    ScheduleLambdaAccount       = var.ScheduleLambdaAccount
    ScheduleRdsClusters         = var.ScheduleRdsClusters
    SchedulerFrequency          = var.SchedulerFrequency
    SchedulingActive            = var.SchedulingActive
    StartedTags                 = var.StartedTags
    StoppedTags                 = var.StoppedTags
    TagName                     = var.TagName
    Trace                       = var.Trace
    UseCloudWatchMetrics        = var.UseCloudWatchMetrics
    UsingAWSOrganizations       = var.UsingAWSOrganizations
  }
  template_body = file("./modules/HubScheduler/files/instance-scheduler-on-aws.template")  ### We create CF resource and use template file instance-scheduler-on-aws.template provided by AWS to deploy all that is needed. DynamoDB, EC2, Lambda, Cloudwatch, KMS, SNS, IAM, EventBridge.
}



resource "aws_cloudformation_stack" "stackschedule" {
  name         = var.NameSchedule
  capabilities = ["CAPABILITY_IAM"]
  depends_on   = [aws_cloudformation_stack.stack]
    parameters = {
      ServiceInstanceScheduleServiceTokenARN = aws_cloudformation_stack.stack.outputs.ServiceInstanceScheduleServiceToken
    }
  template_body = templatefile("./modules/HubScheduler/files/schedules.yml", local.vars)  ### In this template file schedules.yml we define all interval for inactivity. This template contains what was/is working in the AllocateSoftware Account. For test I have created a Schedule named Iko so I can check and verify functionality.
}
```

### Remote
This needs to be executed on Remote Accounts. All that creates is an IAM role so that the HUB can execute tasks on RDS and EC2 instances.
This is the input config file:
 ```
module "AWSInstanceSchedulerHub" {
  source = "./modules/RemoteScheduler"

  Name                        = "AWSInstanceSchedulerRemote"   ### Name of the CF.
  InstanceSchedulerAccount      = "443367186286"   ### Account ID of the Management Account
  Namespace = "MainAWSInstanceSchedulerHub"    ### To link which Namespace to be used. Horizontal scale.
  UsingAWSOrganizations = "Yes"
}
 ```
And the execution instance_schedules_cf.tf:

```
resource "aws_cloudformation_stack" "stack" {
  name         = var.Name
  capabilities = ["CAPABILITY_NAMED_IAM"]
  parameters = {
        InstanceSchedulerAccount = var.InstanceSchedulerAccount
        Namespace = var.Namespace
        UsingAWSOrganizations = var.UsingAWSOrganizations
  }
  template_body = file("./modules/RemoteScheduler/files/aws-instance-scheduler-remote.template")  ### This template is managed by AWS.

```
## Good to know
In the DynamoDB 3 tables are created. What you need is the conf table that is populated with info from schedules.yml and you can see all schedules and table state where you can find all detected instances (containing correct Tag).

## Something to be checked and confirmed:
EC2 Instances with Encrypted EBS Volumes
If your EC2 instances have EBS volumes encrypted with customer-managed KMS keys, you must give the instance scheduler role the KMS:CreateGrant permission to be able to start those instances. For more information, refer to https://docs.aws.amazon.com/solutions/latest/instance-scheduler-on-aws/troubleshooting.html#encrypted-ec2-instances-not-starting.
KMS:CreateGrant - is added manually in the template CF file and I can see it in the IAM role but I didn't test this.

If you do test with "Iko" schedule you need to specify this TAG on the endpoints: Schedule      AWSInstanceSchedules-iko


## Conclusion
The configuration works and was tested to start stop EC2 and RDS on the HUB account and only EC2 on Remote account.
