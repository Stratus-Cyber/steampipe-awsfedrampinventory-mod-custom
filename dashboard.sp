dashboard "FedRAMP-Inventory-Dashboard" {
	title = "FedRAMP Inventory Dashboard"


container {
  title = "Charts"
  width = 12
chart {
  type  = "bar"
  title = "Assets By OS"
  width = 6
    sql = <<-EOQ

WITH vpc_list as (
    SELECT DISTINCT
      vpc_id,
      title
    from
      aws_vpc
  ),
    all_ips as (
    select
	  attached_instance_id,
      network_interface_id,
      pvt_ip_addr -> 'Association' ->> 'PublicIp' as "IP",
      'Public' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr -> 'Association' ->> 'PublicIp' is not null
    UNION ALL
    select
	  attached_instance_id,		
      network_interface_id,
      pvt_ip_addr ->> 'PrivateIpAddress' as "IP",
      'Private' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr ->> 'PrivateIpAddress' is not null
	  and attached_instance_id is not null
  ),
  ami_list as (
    select
      image_id,
      name
    from
      aws_ec2_ami
  ),  
  network_interfaces as (
    SELECT
      file_system_id,
      jsonb_array_elements_text(network_interface_ids) "interface"
    FROM
      aws_fsx_file_system
  ),
  fsx_data as (
    SELECT
      --network_interfaces.interface,
      aws_fsx_file_system.title as "Unique Asset Identifier",
      jsonb_array_elements_text(network_interface_ids) "interface",
      --'' as "IPv4 or IPv6 Address",
      --	'' as "Public",
      dns_name as "DNS Name or URL",
      '' as "NetBIOS Name",
      '' as "MAC Address",
      tags ->> 'authenticated_scan' as "Authenticated Scan",
      tags ->> 'baseline_configuration' as "Baseline Configuration Name",
      '' as "OS Name and Version",
      '' as "Location",
      'AWS ALB' as "Asset Type",
      '' as "Hardware Make/Model",
      '' as "In Latest Scan",
      '' as "Software/Database Vendor",
      '' as "Software/Database Name & Version",
      '' as "Patch Level",
      '' as "Diagram Label",
      tags ->> 'Comments' as "Comments",
      arn as "Serial #/Asset Tag#",
      CASE
        WHEN vpc_list.title is null THEN aws_fsx_file_system.vpc_id
        ELSE vpc_list.title
      END as "VLAN/Network ID",
      tags ->> 'application_admin' as "Application Owner",
      tags ->> 'system_owner' as "System Owner",
      tags ->> 'function' as "Function",
      '' as "End-of-Life"
    FROM
      aws_fsx_file_system
      INNER join vpc_list ON vpc_list.vpc_id = aws_fsx_file_system.vpc_id
  ),
  
  Full_Inventory as (
  --Application Load Balancer
  SELECT
	aws_ec2_application_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
		'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_ec2_application_load_balancer.vpc_id
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_application_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_application_load_balancer.vpc_id
	
UNION

-- Classic Load Balancer
SELECT
	aws_ec2_classic_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
	    tags ->> 'public' as "Public",		

--CASE
--	WHEN scheme = 'internet-facing' THEN 'Yes'
--		ELSE 'No'
--	END as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS Load Balancer' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_ec2_classic_load_balancer.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_classic_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_classic_load_balancer.vpc_id
	
	-- Directory Service	
	UNION
	
	SELECT
	aws_directory_service_directory.title as "Unique Asset Identifier",
	jsonb_array_elements_text(dns_ip_addrs) "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	access_url as "DNS Name or URL",
	directory_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Directory Service' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	type as "Software/Database Vendor",
	edition as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN vpc_settings ->> 'VpcId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'system_owner' as "System Administrator/Owner",
	tags ->> 'application_admin' as "Application Administrator/Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_directory_service_directory
	left join vpc_list ON vpc_list.vpc_id = aws_directory_service_directory.vpc_settings ->> 'VpcId'
	
	-- EC2 Fedramp Inventory
	UNION
	
select
  instance_id as "Unique Asset Identifier",
    CASE
    WHEN "IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  'Yes' as "Virtual",
      tags ->> 'public' as "Public",		
  --CASE
    --WHEN "IP_Type" = 'Public' THEN "IP"
  --END as "Public",
  private_dns_name as "DNS Name or URL",
  aws_ec2_instance.title as "NetBIOS Name",
  '' as "MAC Address",
  tags ->> 'authenticated_scan' as "Authenticated Scan",
  tags ->> 'baseline_configuration' as "Baseline Configuration Name",
  platform_details as "OS Name and Version",
  placement_availability_zone as "Location",
  'AWS EC2' as "Asset Type",
  instance_type as "Hardware Make/Model",
  '' as "In Latest Scan",
  CASE
    WHEN ami_list.name is null THEN aws_ec2_instance.image_id
    ELSE ami_list.name
  END as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  tags ->> 'Comments' as "Comments",
  aws_ec2_instance.arn as "Serial #/Asset Tag#",
  vpc_list.title as "VLAN/Network ID",
  tags ->> 'application_admin' as "Application Owner",
  tags ->> 'system_owner' as "System Owner",
  tags ->> 'function' as "Function",
  '' as "End-of-Life"
from
  aws_ec2_instance
  left join all_ips ON all_ips.attached_instance_id = aws_ec2_instance.instance_id
  left join vpc_list ON vpc_list.vpc_id = aws_ec2_instance.vpc_id
  left join ami_list ON ami_list.image_id = aws_ec2_instance.image_id
where
  instance_state = 'running'
	
	-- FSX File System
	UNION
	
	SELECT
  "Unique Asset Identifier",
  CASE
    WHEN all_ips."IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  	'Yes' as "Virtual",
	'' as "Public",
  --CASE
    --WHEN all_ips."IP_Type" = 'Public' THEN all_ips."IP"
  --END as "Public",
  "DNS Name or URL",
  '' as "NetBIOS Name",
  '' as "MAC Address",
  "Authenticated Scan",
  "Baseline Configuration Name",
  '' as "OS Name and Version",
  '' as "Location",
  'AWS ALB' as "Asset Type",
  '' as "Hardware Make/Model",
  '' as "In Latest Scan",
  '' as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  "Comments",
  '' as "Serial #/Asset Tag#",
  "VLAN/Network ID",
  "Application Owner",
  "System Owner",
  "Function",
  "End-of-Life"
FROM
  fsx_data
  inner join all_ips ON all_ips.network_interface_id = fsx_data.interface
  
  
  --Internet Gateway
UNION

 SELECT
	aws_vpc_internet_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	internet_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Internet Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#", 
	CASE
		WHEN vpc_list.title is null THEN aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_internet_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
	
	--Network Load Balancer
	
	UNION
	
SELECT
	aws_ec2_network_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS NLB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#",
	CASE
		WHEN vpc_list.title is null THEN aws_ec2_network_load_balancer.vpc_id
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_network_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_network_load_balancer.vpc_id
	
	-- Open Search
	
	UNION
	
	  SELECT
	aws_opensearch_domain.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	  	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	--dns_name as "DNS Name or URL",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_opensearch_domain.vpc_options ->> 'VPCId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_opensearch_domain
	left join vpc_list ON vpc_list.vpc_id = aws_opensearch_domain.vpc_options ->> 'VPCId'
	
	-- RDS Fedramp inventory
	
	UNION
SELECT
	text(db_instance_identifier) as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",			
	--'publicly_accessible' as "Public",
	endpoint_address || ':' || endpoint_port as "DNS Name or URL",
	resource_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS RDS' as "Asset Type",
	class as "Hardware Make/Model",
	'' as "In Latest Scan",
	engine as "Software/Database Vendor",
	engine_version as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	db_subnet_group_name as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_rds_db_instance	
	
	-- S3 bucket inventory
	UNION
SELECT
	title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS S3' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	'' as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_s3_bucket	
	
-- Subnet VPC Inventory

UNION
SELECT
	aws_vpc_subnet.title as "Unique Asset Identifier",
	text(cidr_block) as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	subnet_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS VPC Subnet' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	subnet_arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_subnet.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_subnet
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_subnet.vpc_id
	
	-- VPC Nat Gateway Inventory
	
UNION

SELECT
	aws_vpc_nat_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	nat_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS VPC NAT Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_nat_gateway.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_nat_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_nat_gateway.vpc_id
)
	
SELECT "OS Name and Version", COUNT(DISTINCT "Unique Asset Identifier") AS "Inventory Count"
FROM Full_Inventory
WHERE "Asset Type" = 'AWS EC2'
AND "OS Name and Version" is not null
GROUP BY "OS Name and Version"
ORDER BY "Inventory Count" DESC


  EOQ
}

chart {
  type  = "bar"
  title = "Unique Assets By Type"
  width = 6
    sql = <<-EOQ

WITH vpc_list as (
    SELECT DISTINCT
      vpc_id,
      title
    from
      aws_vpc
  ),
    all_ips as (
    select
	  attached_instance_id,
      network_interface_id,
      pvt_ip_addr -> 'Association' ->> 'PublicIp' as "IP",
      'Public' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr -> 'Association' ->> 'PublicIp' is not null
    UNION ALL
    select
	  attached_instance_id,		
      network_interface_id,
      pvt_ip_addr ->> 'PrivateIpAddress' as "IP",
      'Private' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr ->> 'PrivateIpAddress' is not null
	  and attached_instance_id is not null
  ),
  ami_list as (
    select
      image_id,
      name
    from
      aws_ec2_ami
  ),  
  network_interfaces as (
    SELECT
      file_system_id,
      jsonb_array_elements_text(network_interface_ids) "interface"
    FROM
      aws_fsx_file_system
  ),
  fsx_data as (
    SELECT
      --network_interfaces.interface,
      aws_fsx_file_system.title as "Unique Asset Identifier",
      jsonb_array_elements_text(network_interface_ids) "interface",
      --'' as "IPv4 or IPv6 Address",
      --	'' as "Public",
      dns_name as "DNS Name or URL",
      '' as "NetBIOS Name",
      '' as "MAC Address",
      tags ->> 'authenticated_scan' as "Authenticated Scan",
      tags ->> 'baseline_configuration' as "Baseline Configuration Name",
      '' as "OS Name and Version",
      '' as "Location",
      'AWS ALB' as "Asset Type",
      '' as "Hardware Make/Model",
      '' as "In Latest Scan",
      '' as "Software/Database Vendor",
      '' as "Software/Database Name & Version",
      '' as "Patch Level",
      '' as "Diagram Label",
      tags ->> 'Comments' as "Comments",
      arn as "Serial #/Asset Tag#",
      CASE
        WHEN vpc_list.title is null THEN aws_fsx_file_system.vpc_id
        ELSE vpc_list.title
      END as "VLAN/Network ID",
      tags ->> 'application_admin' as "Application Owner",
      tags ->> 'system_owner' as "System Owner",
      tags ->> 'function' as "Function",
      '' as "End-of-Life"
    FROM
      aws_fsx_file_system
      INNER join vpc_list ON vpc_list.vpc_id = aws_fsx_file_system.vpc_id
  ),
  
  Full_Inventory as (
  --Application Load Balancer
  SELECT
	aws_ec2_application_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
		'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_ec2_application_load_balancer.vpc_id
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_application_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_application_load_balancer.vpc_id
	
UNION

-- Classic Load Balancer
SELECT
	aws_ec2_classic_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
	    tags ->> 'public' as "Public",		

--CASE
--	WHEN scheme = 'internet-facing' THEN 'Yes'
--		ELSE 'No'
--	END as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS Load Balancer' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_ec2_classic_load_balancer.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_classic_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_classic_load_balancer.vpc_id
	
	-- Directory Service	
	UNION
	
	SELECT
	aws_directory_service_directory.title as "Unique Asset Identifier",
	jsonb_array_elements_text(dns_ip_addrs) "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	access_url as "DNS Name or URL",
	directory_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Directory Service' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	type as "Software/Database Vendor",
	edition as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN vpc_settings ->> 'VpcId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'system_owner' as "System Administrator/Owner",
	tags ->> 'application_admin' as "Application Administrator/Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_directory_service_directory
	left join vpc_list ON vpc_list.vpc_id = aws_directory_service_directory.vpc_settings ->> 'VpcId'
	
	-- EC2 Fedramp Inventory
	UNION
	
select
  instance_id as "Unique Asset Identifier",
    CASE
    WHEN "IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  'Yes' as "Virtual",
      tags ->> 'public' as "Public",		
  --CASE
    --WHEN "IP_Type" = 'Public' THEN "IP"
  --END as "Public",
  private_dns_name as "DNS Name or URL",
  aws_ec2_instance.title as "NetBIOS Name",
  '' as "MAC Address",
  tags ->> 'authenticated_scan' as "Authenticated Scan",
  tags ->> 'baseline_configuration' as "Baseline Configuration Name",
  platform_details as "OS Name and Version",
  placement_availability_zone as "Location",
  'AWS EC2' as "Asset Type",
  instance_type as "Hardware Make/Model",
  '' as "In Latest Scan",
  CASE
    WHEN ami_list.name is null THEN aws_ec2_instance.image_id
    ELSE ami_list.name
  END as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  tags ->> 'Comments' as "Comments",
  aws_ec2_instance.arn as "Serial #/Asset Tag#",
  vpc_list.title as "VLAN/Network ID",
  tags ->> 'application_admin' as "Application Owner",
  tags ->> 'system_owner' as "System Owner",
  tags ->> 'function' as "Function",
  '' as "End-of-Life"
from
  aws_ec2_instance
  left join all_ips ON all_ips.attached_instance_id = aws_ec2_instance.instance_id
  left join vpc_list ON vpc_list.vpc_id = aws_ec2_instance.vpc_id
  left join ami_list ON ami_list.image_id = aws_ec2_instance.image_id
where
  instance_state = 'running'
	
	-- FSX File System
	UNION
	
	SELECT
  "Unique Asset Identifier",
  CASE
    WHEN all_ips."IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  	'Yes' as "Virtual",
	'' as "Public",
  --CASE
    --WHEN all_ips."IP_Type" = 'Public' THEN all_ips."IP"
  --END as "Public",
  "DNS Name or URL",
  '' as "NetBIOS Name",
  '' as "MAC Address",
  "Authenticated Scan",
  "Baseline Configuration Name",
  '' as "OS Name and Version",
  '' as "Location",
  'AWS ALB' as "Asset Type",
  '' as "Hardware Make/Model",
  '' as "In Latest Scan",
  '' as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  "Comments",
  '' as "Serial #/Asset Tag#",
  "VLAN/Network ID",
  "Application Owner",
  "System Owner",
  "Function",
  "End-of-Life"
FROM
  fsx_data
  inner join all_ips ON all_ips.network_interface_id = fsx_data.interface
  
  
  --Internet Gateway
UNION

 SELECT
	aws_vpc_internet_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	internet_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Internet Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#", 
	CASE
		WHEN vpc_list.title is null THEN aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_internet_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
	
	--Network Load Balancer
	
	UNION
	
SELECT
	aws_ec2_network_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS NLB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#",
	CASE
		WHEN vpc_list.title is null THEN aws_ec2_network_load_balancer.vpc_id
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_network_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_network_load_balancer.vpc_id
	
	-- Open Search
	
	UNION
	
	  SELECT
	aws_opensearch_domain.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	  	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	--dns_name as "DNS Name or URL",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_opensearch_domain.vpc_options ->> 'VPCId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_opensearch_domain
	left join vpc_list ON vpc_list.vpc_id = aws_opensearch_domain.vpc_options ->> 'VPCId'
	
	-- RDS Fedramp inventory
	
	UNION
SELECT
	text(db_instance_identifier) as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",			
	--'publicly_accessible' as "Public",
	endpoint_address || ':' || endpoint_port as "DNS Name or URL",
	resource_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS RDS' as "Asset Type",
	class as "Hardware Make/Model",
	'' as "In Latest Scan",
	engine as "Software/Database Vendor",
	engine_version as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	db_subnet_group_name as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_rds_db_instance	
	
	-- S3 bucket inventory
	UNION
SELECT
	title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS S3' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	'' as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_s3_bucket	
	
-- Subnet VPC Inventory

UNION
SELECT
	aws_vpc_subnet.title as "Unique Asset Identifier",
	text(cidr_block) as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	subnet_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS VPC Subnet' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	subnet_arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_subnet.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_subnet
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_subnet.vpc_id
	
	-- VPC Nat Gateway Inventory
	
UNION

SELECT
	aws_vpc_nat_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	nat_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS VPC NAT Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_nat_gateway.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_nat_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_nat_gateway.vpc_id
)
	
SELECT "Asset Type", COUNT(DISTINCT "Unique Asset Identifier") AS "Inventory Count"
FROM Full_Inventory
GROUP BY "Asset Type"
ORDER BY "Inventory Count" DESC;


  EOQ
}
}  

card {
  sql = <<-EOQ
WITH vpc_list as (
    SELECT DISTINCT
      vpc_id,
      title
    from
      aws_vpc
  ),
    all_ips as (
    select
	  attached_instance_id,
      network_interface_id,
      pvt_ip_addr -> 'Association' ->> 'PublicIp' as "IP",
      'Public' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr -> 'Association' ->> 'PublicIp' is not null
    UNION ALL
    select
	  attached_instance_id,		
      network_interface_id,
      pvt_ip_addr ->> 'PrivateIpAddress' as "IP",
      'Private' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr ->> 'PrivateIpAddress' is not null
	  and attached_instance_id is not null
  ),
  ami_list as (
    select
      image_id,
      name
    from
      aws_ec2_ami
  ),  
  network_interfaces as (
    SELECT
      file_system_id,
      jsonb_array_elements_text(network_interface_ids) "interface"
    FROM
      aws_fsx_file_system
  ),
  fsx_data as (
    SELECT
      --network_interfaces.interface,
      aws_fsx_file_system.title as "Unique Asset Identifier",
      jsonb_array_elements_text(network_interface_ids) "interface",
      --'' as "IPv4 or IPv6 Address",
      --	'' as "Public",
      dns_name as "DNS Name or URL",
      '' as "NetBIOS Name",
      '' as "MAC Address",
      tags ->> 'authenticated_scan' as "Authenticated Scan",
      tags ->> 'baseline_configuration' as "Baseline Configuration Name",
      '' as "OS Name and Version",
      '' as "Location",
      'AWS FSX' as "Asset Type",
      '' as "Hardware Make/Model",
      '' as "In Latest Scan",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",		
      '' as "Patch Level",
      tags ->> 'diagram_label' as "Diagram Label",
      tags ->> 'Comments' as "Comments",
      arn as "Serial #/Asset Tag#",
      CASE
        WHEN vpc_list.title is null THEN aws_fsx_file_system.vpc_id
        ELSE vpc_list.title
      END as "VLAN/Network ID",
      tags ->> 'application_admin' as "Application Owner",
      tags ->> 'system_owner' as "System Owner",
      tags ->> 'function' as "Function",
      tags ->> 'end_of_life' as "End-of-Life"
    FROM
      aws_fsx_file_system
      INNER join vpc_list ON vpc_list.vpc_id = aws_fsx_file_system.vpc_id
  ),
  
  images as (
select
  *,
	jsonb_array_elements_text(image_tags) as "image_tag"
from
  aws_ecr_image

)  
  
  
  --Application Load Balancer
  SELECT
	aws_ec2_application_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
		'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",		
	'' as "Patch Level",
	tags ->> 'diagram_label' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_ec2_application_load_balancer.vpc_id
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	tags ->> 'end_of_life' as "End-of-Life"
FROM
	aws_ec2_application_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_application_load_balancer.vpc_id
	
UNION

-- Classic Load Balancer
SELECT
	aws_ec2_classic_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
	    tags ->> 'public' as "Public",		

--CASE
--	WHEN scheme = 'internet-facing' THEN 'Yes'
--		ELSE 'No'
--	END as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS Load Balancer' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",		
	'' as "Patch Level",
	tags ->> 'diagram_label' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_ec2_classic_load_balancer.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	tags ->> 'end_of_life' as "End-of-Life"
FROM
	aws_ec2_classic_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_classic_load_balancer.vpc_id
	
	-- Directory Service	
	UNION
	
	SELECT
	CASE
    WHEN aws_directory_service_directory.title is null THEN directory_id
    ELSE aws_directory_service_directory.title
  END as "Unique Asset Identifier",
	--aws_directory_service_directory.title as "Unique Asset Identifier",
	jsonb_array_elements_text(dns_ip_addrs) "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	access_url as "DNS Name or URL",
	'' as "NetBIOS Name",
	--directory_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Directory Service' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	--type as "Software/Database Vendor",
	--edition as "Software/Database Name & Version",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",		
	'' as "Patch Level",
	tags ->> 'diagram_label' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN vpc_settings ->> 'VpcId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'system_owner' as "System Administrator/Owner",
	tags ->> 'application_admin' as "Application Administrator/Owner",
	tags ->> 'function' as "Function",
	tags ->> 'end_of_life' as "End-of-Life"
FROM
	aws_directory_service_directory
	left join vpc_list ON vpc_list.vpc_id = aws_directory_service_directory.vpc_settings ->> 'VpcId'
	
	-- EC2 Fedramp Inventory
	UNION
	
select
  --instance_id as "Unique Asset Identifier",
      CASE
    WHEN aws_ec2_instance.title is not null THEN aws_ec2_instance.title
	ELSE instance_id
  END as "Unique Asset Identifier",
    CASE
    WHEN "IP_Type" = 'Private' or "IP_Type" = 'Public' THEN "IP"
  END as "IPv4 or IPv6 Address",
  'Yes' as "Virtual",
      tags ->> 'public' as "Public",		
  --CASE
    --WHEN "IP_Type" = 'Public' THEN "IP"
  --END as "Public",
  private_dns_name as "DNS Name or URL",
  '' as "NetBIOS Name",
  --aws_ec2_instance.title as "NetBIOS Name",
  '' as "MAC Address",
  tags ->> 'authenticated_scan' as "Authenticated Scan",
  tags ->> 'baseline_configuration' as "Baseline Configuration Name",
  platform_details as "OS Name and Version",
  placement_availability_zone as "Location",
  'AWS EC2' as "Asset Type",
  instance_type as "Hardware Make/Model",
  '' as "In Latest Scan",
 --CASE
 --   WHEN ami_list.name is null THEN aws_ec2_instance.image_id
--    ELSE ami_list.name
 -- END as "Software/Database Vendor",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
		WHEN ami_list.name IS NOT NULL THEN ami_list.name
		WHEN aws_ec2_instance.image_id IS NOT NULL THEN aws_ec2_instance.image_id		
        ELSE tags ->> 'software_vendor'
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NULL OR tags ->> 'software_version' = '') THEN ''
        ELSE tags ->> 'software_version'
    END as "Software/Database Name & Version",
  '' as "Patch Level",
  tags ->> 'diagram_label' as "Diagram Label",
  tags ->> 'Comments' as "Comments",
  aws_ec2_instance.arn as "Serial #/Asset Tag#",
  vpc_list.title as "VLAN/Network ID",
  tags ->> 'application_admin' as "Application Owner",
  tags ->> 'system_owner' as "System Owner",
  tags ->> 'function' as "Function",
  tags ->> 'end_of_life' as "End-of-Life"
from
  aws_ec2_instance
  left join all_ips ON all_ips.attached_instance_id = aws_ec2_instance.instance_id
  left join vpc_list ON vpc_list.vpc_id = aws_ec2_instance.vpc_id
  left join ami_list ON ami_list.image_id = aws_ec2_instance.image_id
where
  instance_state = 'running'
	
	-- FSX File System
	UNION
	
	SELECT
  "Unique Asset Identifier",
  CASE
    WHEN all_ips."IP_Type" = 'Private' or all_ips."IP_Type" = 'Public' THEN "IP"
  END as "IPv4 or IPv6 Address",
  	'Yes' as "Virtual",
	'' as "Public",
  --CASE
    --WHEN all_ips."IP_Type" = 'Public' THEN all_ips."IP"
  --END as "Public",
  "DNS Name or URL",
  '' as "NetBIOS Name",
  '' as "MAC Address",
  "Authenticated Scan",
  "Baseline Configuration Name",
  '' as "OS Name and Version",
  '' as "Location",
  'AWS FSX' as "Asset Type",
  '' as "Hardware Make/Model",
  '' as "In Latest Scan",
"Software/Database Vendor",	
"Software/Database Name & Version",
  '' as "Patch Level",
  "Diagram Label",
  "Comments",
 "Serial #/Asset Tag#",
  "VLAN/Network ID",
  "Application Owner",
  "System Owner",
  "Function",
  "End-of-Life"
FROM
  fsx_data
  inner join all_ips ON all_ips.network_interface_id = fsx_data.interface
  
  
  --Internet Gateway
UNION

SELECT
  CASE
    WHEN aws_vpc_internet_gateway.title is null THEN internet_gateway_id
    ELSE aws_vpc_internet_gateway.title
  END as "Unique Asset Identifier",
  --aws_vpc_internet_gateway.title as "Unique Asset Identifier",
  '' as "IPv4 or IPv6 Address",
  'Yes' as "Virtual",
  tags ->> 'public' as "Public",
  --'' as "Public",
  '' as "DNS Name or URL",
  --	internet_gateway_id as "NetBIOS Name",
  '' as "NetBIOS Name",
  '' as "MAC Address",
  tags ->> 'authenticated_scan' as "Authenticated Scan",
  tags ->> 'baseline_configuration' as "Baseline Configuration Name",
  '' as "OS Name and Version",
  region as "Location",
  'AWS Internet Gateway' as "Asset Type",
  '' as "Hardware Make/Model",
  '' as "In Latest Scan",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",		
  '' as "Patch Level",
  tags ->> 'diagram_label' as "Diagram Label",
  tags ->> 'Comments' as "Comments",
  jsonb_array_elements_text(akas) as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
  tags ->> 'application_admin' as "Application Owner",
  tags ->> 'system_owner' as "System Owner",
  tags ->> 'function' as "Function",
  tags ->> 'end_of_life' as "End-of-Life"
FROM
  aws_vpc_internet_gateway
  left join vpc_list ON vpc_list.vpc_id = aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'

	--Network Load Balancer
	
	UNION
	
SELECT
	aws_ec2_network_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS NLB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",		
	'' as "Patch Level",
	tags ->> 'diagram_label' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#",
	CASE
		WHEN vpc_list.title is null THEN aws_ec2_network_load_balancer.vpc_id
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	tags ->> 'end_of_life' as "End-of-Life"
FROM
	aws_ec2_network_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_network_load_balancer.vpc_id
	
	-- Open Search
	
	UNION
	
	  SELECT
	aws_opensearch_domain.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	  	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	--dns_name as "DNS Name or URL",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS Open Search' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",		
	'' as "Patch Level",
	tags ->> 'diagram_label' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_opensearch_domain.vpc_options ->> 'VPCId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	tags ->> 'end_of_life' as "End-of-Life"
FROM
	aws_opensearch_domain
	left join vpc_list ON vpc_list.vpc_id = aws_opensearch_domain.vpc_options ->> 'VPCId'
	
	-- RDS Fedramp inventory
	
	UNION

SELECT
	  CASE
    WHEN title is null THEN resource_id
    ELSE title
  END as "Unique Asset Identifier",
	--text(db_instance_identifier) as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",			
	--'publicly_accessible' as "Public",
	endpoint_address || ':' || endpoint_port as "DNS Name or URL",
	--resource_id as "NetBIOS Name",
		'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS RDS' as "Asset Type",
	class as "Hardware Make/Model",
	'' as "In Latest Scan",
	-- engine as "Software/Database Vendor",
	-- engine_version as "Software/Database Name & Version",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
		WHEN engine IS NOT NULL THEN engine
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
		WHEN engine_version IS NOT NULL THEN engine_version		
        ELSE ''
    END as "Software/Database Name & Version",	
	'' as "Patch Level",
	tags ->> 'diagram_label' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	db_subnet_group_name as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	tags ->> 'end_of_life' as "End-of-Life"
FROM
	aws_rds_db_instance	
	
	-- S3 bucket inventory
	UNION
SELECT
	title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS S3' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",	
	'' as "Patch Level",
	tags ->> 'diagram_label' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	'' as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	tags ->> 'end_of_life' as "End-of-Life"
FROM
	aws_s3_bucket	
	
-- Subnet VPC Inventory

UNION

SELECT
	  CASE
    WHEN aws_vpc_subnet.title is null THEN subnet_id
    ELSE aws_vpc_subnet.title
  END as "Unique Asset Identifier",
	--aws_vpc_subnet.title as "Unique Asset Identifier",
	text(cidr_block) as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	--subnet_id as "NetBIOS Name",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS VPC Subnet' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",	
	'' as "Patch Level",
	tags ->> 'diagram_label' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	subnet_arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_subnet.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	tags ->> 'end_of_life' as "End-of-Life"
FROM
	aws_vpc_subnet
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_subnet.vpc_id
	
	-- VPC Nat Gateway Inventory
	
UNION

SELECT
	  CASE
    WHEN aws_vpc_nat_gateway.title is null THEN nat_gateway_id
    ELSE aws_vpc_nat_gateway.title
  END as "Unique Asset Identifier",
	--aws_vpc_nat_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	--nat_gateway_id as "NetBIOS Name",
		'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS VPC NAT Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",	
	'' as "Patch Level",
	tags ->> 'diagram_label' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_nat_gateway.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	tags ->> 'end_of_life' as "End-of-Life"
FROM
	aws_vpc_nat_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_nat_gateway.vpc_id
	
UNION 

-- ECR Repository Inventory
  SELECT DISTINCT
	repository_name as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
		'Yes' as "Virtual",
    tags ->> 'public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ECR Repository' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",	
	'' as "Patch Level",
	tags ->> 'diagram_label' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	repository_uri as "Serial #/Asset Tag#",
  --CASE
   -- WHEN vpc_list.title is null THEN aws_ec2_application_load_balancer.vpc_id
  --  ELSE vpc_list.title
--  END as "VLAN/Network ID",
	'' as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	tags ->> 'end_of_life' as "End-of-Life"
FROM
	aws_ecr_repository repo
	
	UNION
	
	--AWS ECR Images Inventory
	
	  SELECT DISTINCT
	image_uri as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
		'Yes' as "Virtual",
	'' as "Public",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	'' as "Authenticated Scan",
	'' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ECR Image' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
    CASE
        WHEN (image_tags ->> 'software_vendor' IS NOT NULL AND image_tags ->> 'software_vendor' != '') THEN image_tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (image_tags ->> 'software_version' IS NOT NULL AND image_tags ->> 'software_version' != '') THEN image_tags ->> 'software_version'
		WHEN (image_tags ->> 'software_version' IS NULL OR image_tags ->> 'software_version' = '') THEN split_part(image_uri, ':', 2)
        ELSE ''
    END as "Software/Database Name & Version",	
	-- split_part(image_uri, ':', 2) as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	'' as "Comments",
	image_uri as "Serial #/Asset Tag#",
  --CASE
   -- WHEN vpc_list.title is null THEN aws_ec2_application_load_balancer.vpc_id
  --  ELSE vpc_list.title
--  END as "VLAN/Network ID",
	'' as "VLAN/Network ID",
	'' as "Application Owner",
	'' as "System Owner",
	'' as "Function",
	'' as "End-of-Life"
FROM
	images
WHERE image_tag = 'latest'






	


	


  EOQ
  title = "AWS Fedramp Inventory"
  width = 8
}



























table {
  title = "AWS FedRAMP Inventory "
  width = 8

  sql   = <<-EOQ
WITH
time_ranked_rds_snapshots AS (
  SELECT 
    db_instance_identifier,
	db_snapshot_identifier,
	create_time,
	status,
    ROW_NUMBER() OVER (PARTITION BY db_instance_identifier ORDER BY create_time DESC) AS rn
  FROM 
    aws_rds_db_snapshot
),
extracted_volumes AS (
  SELECT 
    instance_id, 
    jsonb_array_elements(block_device_mappings) AS volume_data
  FROM 
    aws_ec2_instance
),
volume_ids AS (
  SELECT 
    instance_id,
    volume_data->'Ebs'->>'VolumeId' AS volume_id
  FROM 
    extracted_volumes
),
most_recent_snapshots AS (
  SELECT 
    s.volume_id,
    s.state,  
    s.start_time,
    ROW_NUMBER() OVER (PARTITION BY s.volume_id ORDER BY s.start_time DESC) AS rn
  FROM 
    aws_ebs_snapshot s
  JOIN 
    volume_ids v ON s.volume_id = v.volume_id
),
ec2_volume_snapshots_list AS (
SELECT 
  
  i.instance_id,
  STRING_AGG(
    CONCAT(
      'Volume: ', v.volume_id, 
      ', State: ', COALESCE(m.state, 'N/A'), 
      ', Snapshot Time: ', COALESCE(m.start_time::text, 'N/A')
    ), '; '
  ) AS volume_snapshots,
    STRING_AGG(
    CONCAT(
      v.volume_id, 
      '-', COALESCE(m.state, 'N/A'), 
      '-', COALESCE(m.start_time::text, 'N/A')
    ), '; '
  ) AS volume_snapshots_list
FROM 
  aws_ec2_instance i
LEFT JOIN 
  volume_ids v ON i.instance_id = v.instance_id
LEFT JOIN 
  most_recent_snapshots m ON v.volume_id = m.volume_id AND m.rn = 1
GROUP BY 
  i.instance_id
),
vpc_list as (
    SELECT DISTINCT
      vpc_id,
      title
    from
      aws_vpc
  ),
    all_ips as (
    select
	  attached_instance_id,
      network_interface_id,
      pvt_ip_addr -> 'Association' ->> 'PublicIp' as "IP",
      'Public' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr -> 'Association' ->> 'PublicIp' is not null
    UNION ALL
    select
	  attached_instance_id,		
      network_interface_id,
      pvt_ip_addr ->> 'PrivateIpAddress' as "IP",
      'Private' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr ->> 'PrivateIpAddress' is not null
	  and attached_instance_id is not null
  ),
  ami_list as (
    select
      image_id,
      name
    from
      aws_ec2_ami
  ),
subnet_list as (
  SELECT
    DISTINCT subnet_id,
    title
  from
    aws_vpc_subnet
),  
  network_interfaces as (
    SELECT
      file_system_id,
      jsonb_array_elements_text(network_interface_ids) "interface"
    FROM
      aws_fsx_file_system
  ),
  fsx_data as (
    SELECT
      --network_interfaces.interface,
      aws_fsx_file_system.title as "Unique Asset Identifier",
      jsonb_array_elements_text(network_interface_ids) "interface",
      --'' as "IPv4 or IPv6 Address",
      --	'' as "Public",
      dns_name as "DNS Name or URL",
      '' as "NetBIOS Name",
      '' as "MAC Address",
      tags ->> 'authenticated_scan' as "Authenticated Scan",
      tags ->> 'baseline_configuration' as "Baseline Configuration Name",
      '' as "OS Name and Version",
      '' as "Location",
      'AWS FSX' as "Asset Type",
      '' as "Hardware Make/Model",
      '' as "In Latest Scan",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
        ELSE ''
    END as "Software/Database Name & Version",		
      '' as "Patch Level",
      tags ->> 'diagram_label' as "Diagram Label",
      tags ->> 'Comments' as "Comments",
      arn as "Serial #/Asset Tag#",
      CASE
        WHEN vpc_list.title is null THEN aws_fsx_file_system.vpc_id
        ELSE vpc_list.title
      END as "VLAN/Network ID",
      tags ->> 'application_admin' as "Application Owner",
      tags ->> 'system_owner' as "System Owner",
      tags ->> 'function' as "Function",
      tags ->> 'end_of_life' as "End-of-Life"
    FROM
      aws_fsx_file_system
      INNER join vpc_list ON vpc_list.vpc_id = aws_fsx_file_system.vpc_id
  ),
  
  images as (
select
  *,
	jsonb_array_elements_text(image_tags) as "image_tag"
from
  aws_ecr_image

),
    ssm_inventory as (
    select
      *,
		  c ->> 'AgentType' as agent_type,
  c ->> 'IpAddress' as ip_address,
  c ->> 'AgentVersion' as agent_version,
  c ->> 'ComputerName' as computer_name,
  c ->> 'PlatformName' as platform_name,
  c ->> 'PlatformType' as platform_type,
  c ->> 'ResourceType' as resource_type,
  c ->> 'InstanceStatus' as instance_status,
  c ->> 'PlatformVersion' as platform_version
    from
      aws_ssm_inventory,
		jsonb_array_elements(content) as c
  )
	
	-- EC2 Fedramp Inventory
	
select
  --instance_id as "Unique Asset Identifier",
      CASE
    WHEN aws_ec2_instance.title is not null THEN aws_ec2_instance.title
	ELSE aws_ec2_instance.instance_id
  END as "Unique Asset Identifier",
    CASE
    WHEN "IP_Type" = 'Private' or "IP_Type" = 'Public' THEN "IP"
  END as "IPv4 or IPv6 Address",
  'Yes' as "Virtual",
      tags ->> 'public' as "Public",		
  --CASE
    --WHEN "IP_Type" = 'Public' THEN "IP"
  --END as "Public",
  private_dns_name as "DNS Name or URL",
  ssm_inventory.computer_name as "NetBIOS Name",
  --aws_ec2_instance.title as "NetBIOS Name",
  '' as "MAC Address",
  tags ->> 'authenticated_scan' as "Authenticated Scan",
  tags ->> 'baseline_configuration' as "Baseline Configuration Name",
  ssm_inventory.platform_name || '-' || ssm_inventory.platform_version as "OS Name and Version",
  placement_availability_zone as "Location",
  'AWS EC2' as "Asset Type",
  instance_type as "Hardware Make/Model",
  '' as "In Latest Scan",
 --CASE
 --   WHEN ami_list.name is null THEN aws_ec2_instance.image_id
--    ELSE ami_list.name
 -- END as "Software/Database Vendor",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
		WHEN ami_list.name IS NOT NULL THEN ami_list.name
		WHEN aws_ec2_instance.image_id IS NOT NULL THEN aws_ec2_instance.image_id		
        ELSE tags ->> 'software_vendor'
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NULL OR tags ->> 'software_version' = '') THEN ''
        ELSE tags ->> 'software_version'
    END as "Software/Database Name & Version",
  '' as "Patch Level",
  tags ->> 'diagram_label' as "Diagram Label",
  tags ->> 'Comments' as "Comments",
  aws_ec2_instance.arn as "Serial #/Asset Tag#",
  concat(vpc_list.title, '/', subnet_list.title) as "VLAN/Network ID",
  tags ->> 'application_admin' as "Application Owner",
  tags ->> 'system_owner' as "System Owner",
  tags ->> 'function' as "Function",
  tags ->> 'end_of_life' as "End-of-Life"--,
 -- volume_snapshots_list as "Latest Snapshot"
from
  aws_ec2_instance
  left join all_ips ON all_ips.attached_instance_id = aws_ec2_instance.instance_id
  left join vpc_list ON vpc_list.vpc_id = aws_ec2_instance.vpc_id
  left join ami_list ON ami_list.image_id = aws_ec2_instance.image_id
   left join ssm_inventory ON ssm_inventory.id = aws_ec2_instance.instance_id
   left join subnet_list ON subnet_list.subnet_id = aws_ec2_instance.subnet_id
   --left join ec2_volume_snapshots_list ON ec2_volume_snapshots_list.instance_id = aws_ec2_instance.instance_id
where
  instance_state = 'running'
	
	-- RDS Fedramp inventory
	
	UNION

SELECT
	  CASE
    WHEN title is null THEN resource_id
    ELSE title
  END as "Unique Asset Identifier",
	--text(db_instance_identifier) as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'public' as "Public",			
	--'publicly_accessible' as "Public",
	endpoint_address || ':' || endpoint_port as "DNS Name or URL",
	--resource_id as "NetBIOS Name",
		'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'authenticated_scan' as "Authenticated Scan",
	tags ->> 'baseline_configuration' as "Baseline Configuration Name",
	platform_details as "OS Name and Version",
	availability_zone as "Location",
	'AWS RDS' as "Asset Type",
	class as "Hardware Make/Model",
	'' as "In Latest Scan",
	-- engine as "Software/Database Vendor",
	-- engine_version as "Software/Database Name & Version",
    CASE
        WHEN (tags ->> 'software_vendor' IS NOT NULL AND tags ->> 'software_vendor' != '') THEN tags ->> 'software_vendor'
		WHEN engine IS NOT NULL THEN engine
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (tags ->> 'software_version' IS NOT NULL AND tags ->> 'software_version' != '') THEN tags ->> 'software_version'
		WHEN engine_version IS NOT NULL THEN engine_version		
        ELSE ''
    END as "Software/Database Name & Version",	
	'' as "Patch Level",
	tags ->> 'diagram_label' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	--db_subnet_group_name as "VLAN/Network ID",
	  (
  SELECT string_agg(subnet_info, ', ')
  FROM (
    SELECT DISTINCT concat(
      COALESCE((SELECT v.title FROM aws_vpc v WHERE v.vpc_id = aws_rds_db_instance.vpc_id), aws_rds_db_instance.vpc_id),
      '/',
      COALESCE(s.title, (subnet_data->>'SubnetIdentifier'))
    ) as subnet_info
    FROM jsonb_array_elements(aws_rds_db_instance.subnets) as subnet_data
    LEFT JOIN aws_vpc_subnet s ON s.subnet_id = (subnet_data->>'SubnetIdentifier')
  ) as unique_subnets
) as "VLAN/Network ID",
	tags ->> 'application_admin' as "Application Owner",
	tags ->> 'system_owner' as "System Owner",
	tags ->> 'function' as "Function",
	tags ->> 'end_of_life' as "End-of-Life"--,
  	--CONCAT(rs.db_instance_identifier, '-',rs.status, '-',rs.create_time::text) as "Latest Snapshot"

FROM
	aws_rds_db_instance
	--left join time_ranked_rds_snapshots rs on rs.db_instance_identifier = aws_rds_db_instance.db_instance_identifier
	
	
	UNION
	
	--AWS ECR Images Inventory
	
	  SELECT DISTINCT
	image_uri as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
		'Yes' as "Virtual",
	'' as "Public",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	'' as "Authenticated Scan",
	'' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ECR Image' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
    CASE
        WHEN (image_tags ->> 'software_vendor' IS NOT NULL AND image_tags ->> 'software_vendor' != '') THEN image_tags ->> 'software_vendor'
        ELSE ''
    END as "Software/Database Vendor",	
    CASE
        WHEN (image_tags ->> 'software_version' IS NOT NULL AND image_tags ->> 'software_version' != '') THEN image_tags ->> 'software_version'
		WHEN (image_tags ->> 'software_version' IS NULL OR image_tags ->> 'software_version' = '') THEN split_part(image_uri, ':', 2)
        ELSE ''
    END as "Software/Database Name & Version",	
	-- split_part(image_uri, ':', 2) as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	'' as "Comments",
	image_uri as "Serial #/Asset Tag#",
  --CASE
   -- WHEN vpc_list.title is null THEN aws_ec2_application_load_balancer.vpc_id
  --  ELSE vpc_list.title
--  END as "VLAN/Network ID",
	'' as "VLAN/Network ID",
	'' as "Application Owner",
	'' as "System Owner",
	'' as "Function",
	'' as "End-of-Life"--,
  	--'' as "Latest Snapshot"
FROM
	images
WHERE image_tag = 'latest'



	


  EOQ
}

}
