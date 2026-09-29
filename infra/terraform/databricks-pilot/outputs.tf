output "current_user" {
  value = data.databricks_current_user.me.user_name
}

output "catalogs" {
  value = data.databricks_catalogs.all.ids
}

output "pilot_job_id" {
  value = databricks_job.pilot.id
}