module "AWSInstanceSchedulerHub" {
  source = "./modules/HubScheduler"

  Name                        = "AWSInstanceSchedulerHub"
  NameSchedule                = "AWSInstanceSchedules"
  CreateRdsSnapshot           = "No"
  DefaultTimezone             = "UTC"
  EnableSSMMaintenanceWindows = "Yes"
  LogRetentionDays            = 30
  MemorySize                  = 1536
  Namespace                   = "MainAWSInstanceSchedulerHub"
  Principals                  = "o-isxlj23fyq"
  Regions                     = "us-east-1,us-east-2,us-west-1,us-west-2,ap-south-1,ap-northeast-3,ap-northeast-2,ap-southeast-1,ap-southeast-2,ap-northeast-1,ca-central-1,eu-central-1,eu-west-1,eu-west-2,eu-west-3,eu-north-1,sa-east-1"
  ScheduledServices           = "Both"
  ScheduleLambdaAccount       = "Yes"
  ScheduleRdsClusters         = "Yes"
  SchedulerFrequency          = 5
  SchedulingActive            = "Yes"
  StartedTags                 = "MonitoringEnabled=True,ScheduleStartMsg=Started on {day}/{month}/{year} at {hour}:{minute} {timezone}"
  StoppedTags                 = "MonitoringEnabled=False,ScheduleStopMsg=Stopped on {day}/{month}/{year} at {hour}:{minute} {timezone}"
  TagName                     = "Schedule"
  Trace                       = "Yes"
  UseCloudWatchMetrics        = "Yes"
  UsingAWSOrganizations       = "Yes"

}
