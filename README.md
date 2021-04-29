# puppet-vault

## Table of Contents

1. [Description](#description)
1. [Usage](#usage)
1. [Limitations](#limitations)

## Description

Puppet module that provides a function to access Hashicorp Vault secrets within
Puppet manifests. Utilizes the Deferred Function capabilities of Puppet 6.22+ to
enable client-side lookups at agent run time. Appropriate use cases include delivering
the secret to an input parameter of another module, or rendering a template file that
contains the secret value.

## Usage

Simply declare the function with appropriate parameters to store your secret in 
a variable. Input parameters to the function are ordered (not named).

```
$my_secret_value = Deferred(
    'vault::get_secret', [
      'http://127.0.0.1:8100',         # address of Vault service
      'path/to/my/secret',             # path to secret in Vault 
      'field',                         # field of secret
      false                            # boolean to set whether secret is kv_v2 type
    ]
  )
```

To render a template that contains the secret value, use inline_epp:
```
$variables = {
  'password' => Deferred(
                    'vault::get_secret', [
                    'http://127.0.0.1:8100',
                    'path/to/my/secret',
                    'field',
                    false
                    ]
                )
}

file { '/etc/secrets.conf':
  ensure  => file,
  content => Deferred('inline_epp',
               ['PASSWORD=<%= $password.unwrap %>', $variables]),
}
```

### Ordered Parameters
* `vault_uri`: \[string\] Address of Vault service including protocol and port (required)
* `secret`: \[string\] Path to secret (required)
* `field`: \[string\] Field of secret (required)
* `kv_v2`: \[bool\] Whether the secret is within a kv_v2 mount, which affects how we handle the data payload (required)
* `token_path`: \[string\] If supplied, uses the token value found in a local file - otherwise, the function assumes that Vault authentication is handled via other means, such as AppRole, IAM, etc. (optional)
* `token_wrapped`: \[bool\] Whether the token provided is wrapped (optional - default: false)

## Limitations

This module relies on Puppet Deferred Functions, which are only available in Puppet 6.22+
