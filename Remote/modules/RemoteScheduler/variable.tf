variable "Name" {
	type = string
}
variable "InstanceSchedulerAccount" {
	type = string
	description = "Main accountID where HUB scheduler is possitione"
}
variable "Namespace" {
	type = string
	description = "Namespace of the HUB scheduler"

}
variable "UsingAWSOrganizations" {
	type = string
}
