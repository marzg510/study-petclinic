resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.tf-test-vpc.id

  tags = {
    Name = "tf-test-public-nacl"
  }
}

resource "aws_network_acl_rule" "allow_http_in" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "6"               # TCP
  rule_action    = "allow"
  egress         = false
  # cidr_block     = "163.116.208.22/32"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "allow_ephemeral_in" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  protocol       = "6"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "allow_all_out" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  network_acl_id = aws_network_acl.public.id
}
