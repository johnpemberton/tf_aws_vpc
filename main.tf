resource "aws_vpc" "mod" {
  cidr_block = "${var.cidr}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support = "${var.enable_dns_support}"
  tags = "${merge(map("Name", "vpc-${var.name}"), var.common_tags)}"
}

resource "aws_internet_gateway" "mod" {
  vpc_id = "${aws_vpc.mod.id}"
  tags = "${merge(map("Name", "igw-${var.name}"), var.common_tags)}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.mod.id}"
  propagating_vgws = ["${var.public_propagating_vgws}"]
  tags = "${merge(map("Name", "route-table-public-${var.name}"), var.common_tags)}"
}

resource "aws_route" "public_internet_gateway" {
    route_table_id = "${aws_route_table.public.id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.mod.id}"
}

resource "aws_route_table" "private" {
  count = "${length(var.private_subnets)}"
  vpc_id = "${aws_vpc.mod.id}"
  propagating_vgws = ["${var.private_propagating_vgws}"]
  tags = "${merge(map("Name", "route-table-private-${var.name}-${count.index + 1}"), var.common_tags)}"
}

resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.mod.id}"
  cidr_block = "${var.private_subnets[count.index]}"
  availability_zone = "${var.azs[count.index]}"
  count = "${length(var.private_subnets)}"
  tags = "${merge(map("Name", "subnet-private-${var.name}-${count.index + 1}"), var.common_tags)}"
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.mod.id}"
  cidr_block = "${var.public_subnets[count.index]}"
  availability_zone = "${var.azs[count.index]}"
  count = "${length(var.public_subnets)}"
  tags = "${merge(map("Name", "subnet-public-${var.name}-${count.index + 1}"), var.common_tags)}"

  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "private" {
  count = "${length(var.private_subnets)}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_route_table_association" "public" {
  count = "${length(var.public_subnets)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}
