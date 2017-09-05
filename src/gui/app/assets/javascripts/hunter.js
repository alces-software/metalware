
// Before each poll for newly detected MAC addresses, add the known MAC
// addresses to the request data so we will only receive and append new ones.
$(document).on('beforeAjaxSend.ic', (_event, ajaxSetting, element) => {
  const knownMacAddresses = $(element).
    find('.mac-address').get().
    map(el => el.innerHTML)

  // Encode known MAC addresses in format Rails will decode as an array.
  const knownMacArrayParam = mac => `known_mac_addresses[]=${mac}`
  const knownMacsData = knownMacAddresses.map(knownMacArrayParam).join('&')
  const encodedData = encodeURI(knownMacsData)

  ajaxSetting.data += `&${encodedData}`
})
