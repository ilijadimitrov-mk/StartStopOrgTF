resource "aws_cloudformation_stack" "stack" {
  name         = var.Name
  capabilities = ["CAPABILITY_NAMED_IAM"]
  parameters = {
	InstanceSchedulerAccount = var.InstanceSchedulerAccount
	Namespace = var.Namespace
	UsingAWSOrganizations = var.UsingAWSOrganizations
  }
  template_body = file("./modules/RemoteScheduler/files/aws-instance-scheduler-remote.template")
}
