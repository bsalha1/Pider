#!/bin/sh

set -ue

# Use netfilter iptables instead of legacy.
# ln -sf /usr/sbin/iptables-nft $TARGET_DIR/usr/sbin/iptables
# ln -sf /usr/sbin/ip6tables-nft $TARGET_DIR/usr/sbin/ip6tables