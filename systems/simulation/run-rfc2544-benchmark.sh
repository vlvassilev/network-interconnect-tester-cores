#!/bin/bash
./rfc2544-benchmark/rfc2544-benchmark --config=config.xml --dst-node=tester0 --dst-node-interface=eth1 --src-node=tester0 --src-node-interface=eth0 --dst-mac-address="70:B3:D5:EC:20:10" --src-mac-address="70:B3:D5:EC:20:11" --dst-ipv4-address="192.168.1.145" --src-ipv4-udp-port=49184 --src-ipv4-address="192.168.0.145" --frame-size=64 --trial-time=2 --speed=10000 | tee rfc2544-benchmark-report-verbose.txt | grep ^# | tee rfc2544-benchmark-report.txt

