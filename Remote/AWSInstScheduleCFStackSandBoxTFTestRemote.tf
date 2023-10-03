module "AWSInstanceSchedulerHub" {
  source = "./modules/RemoteScheduler"

  Name                        = "AWSInstanceSchedulerRemote"
  InstanceSchedulerAccount	= "443367186286"
  Namespace = "MainAWSInstanceSchedulerHub"
  UsingAWSOrganizations	= "Yes"
}
