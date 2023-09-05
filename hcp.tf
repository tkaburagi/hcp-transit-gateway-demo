data "hcp_hvn" "main" {
  hvn_id = "hvn"
}

resource "hcp_aws_transit_gateway_attachment" "example" {
  depends_on = [
    aws_ram_principal_association.example,
    aws_ram_resource_association.example,
  ]

  hvn_id                        = data.hcp_hvn.main.hvn_id
  transit_gateway_attachment_id = "example-tgw-attachment"
  transit_gateway_id            = aws_ec2_transit_gateway.transit_gateway.id
  resource_share_arn            = aws_ram_resource_share.example.arn
}

resource "hcp_hvn_route" "route" {
  hvn_link         = data.hcp_hvn.main.self_link
  hvn_route_id     = "hvn-to-tgw-attachment"
  destination_cidr = aws_vpc.vpc_a.cidr_block
  target_link      = hcp_aws_transit_gateway_attachment.example.self_link
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "example" {
  transit_gateway_attachment_id = hcp_aws_transit_gateway_attachment.example.provider_transit_gateway_attachment_id
}