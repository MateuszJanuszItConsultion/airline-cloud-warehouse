Connect-AzAccount -Identity

$resourceGroup = "rg-airline-data-engineering"
$vmName = "vm-airline-airflow"

Stop-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Force