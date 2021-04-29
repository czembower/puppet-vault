# @summary 
#
# A function to retrieve secrets from Hashicorp Vault
#
# @example
#   $my_secret = Deferred(
  #   'vault::get_secret', [
  #     'http://127.0.0.1:8100',        # URI of Vault service
  #     'kv/data/path/to/my/secret',    # path to secret
  #     'field'                         # field/key of secret
  #   ]
  # )
class vault::get_secret {
}
