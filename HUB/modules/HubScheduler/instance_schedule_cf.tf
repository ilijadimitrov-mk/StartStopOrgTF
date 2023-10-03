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
  template_body = file("./modules/HubScheduler/files/instance-scheduler-on-aws.template")
}



resource "aws_cloudformation_stack" "stackschedule" {
  name         = var.NameSchedule
  capabilities = ["CAPABILITY_IAM"]
  depends_on   = [aws_cloudformation_stack.stack]
    parameters = {
      ServiceInstanceScheduleServiceTokenARN = aws_cloudformation_stack.stack.outputs.ServiceInstanceScheduleServiceToken
    }
  template_body = templatefile("./modules/HubScheduler/files/schedules.yml", local.vars)
}

