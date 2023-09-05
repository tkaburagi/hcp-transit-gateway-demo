# ネットワーク構築
resource "aws_vpc" "vpc_a" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

###
resource "aws_eip" "nat" {
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_a.id

}

# RouteTable
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc_a.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block         = data.hcp_hvn.main.cidr_block
    transit_gateway_id = hcp_aws_transit_gateway_attachment.example.transit_gateway_id
  }
  tags = {
    Name = "public"
  }
}

# SubnetRouteTableAssociation
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public.id
}

# NatGateway
resource "aws_nat_gateway" "nat" {
  subnet_id     = aws_subnet.subnet_a.id
  allocation_id = aws_eip.nat.id
}
###

# Transit Gateway作成
resource "aws_ec2_transit_gateway" "transit_gateway" {
  description = "My Transit Gateway"
}

# Transit Gateway Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "attachment_vpc_a" {
  transit_gateway_id                              = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id                                          = aws_vpc.vpc_a.id
  subnet_ids                                      = [aws_subnet.subnet_a.id]
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true
}

resource "aws_ram_resource_share" "example" {
  name                      = "example-resource-share"
  allow_external_principals = true
}

resource "aws_ram_principal_association" "example" {
  resource_share_arn = aws_ram_resource_share.example.arn
  principal          = data.hcp_hvn.main.provider_account_id
}

resource "aws_ram_resource_association" "example" {
  resource_share_arn = aws_ram_resource_share.example.arn
  resource_arn       = aws_ec2_transit_gateway.transit_gateway.arn
}