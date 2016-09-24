//file should be encoded in default OS encoding
function FindProxyForURL(url, host) {
  return "HTTPS <squid host>:3129";
}