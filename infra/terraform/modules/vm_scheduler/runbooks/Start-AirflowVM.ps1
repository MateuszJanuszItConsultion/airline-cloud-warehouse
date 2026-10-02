Connect-AzAccount -Identity

$resourceGroup = "rg-airline-data-engineering"
$vmName = "vm-airline-airflow"

Start-AzVM -ResourceGroupName $resourceGroup -Name $vmName