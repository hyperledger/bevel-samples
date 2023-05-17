## DSCP-APP

This folder contains the files that are needed for the deployment of a sample supply chain application on a Substrate based DLT Network that has been deployed using Hyperledger Bevel. This application uses a node.js API to support communication to the Substrate based dscp-node and an IPFS node via polkadot.js API.

### Folder Structure

***

```
dscp-app
|--charts
   |--certissuer
   |--dscp-api
   |--dscp-frontend
   |--dscp-identity-service
   |--inteli-api
   |--postgresql
|--configuration
|--releases
|--tests
```

### Pre-requisites

***

- Substrate DSCP network of one or more organizations. A complete supplychain network will have the following organizations:
  - OEM - Original Equipment Manufacturer (admin organization)
  - Tier 1 Supplier
  - Tier 2 Supplier
- IPFS node for each organization

### Authentication

***

The dscp-api optionally uses an Auth0 Machine to Machine API to issue a JSON Web Token for authentication on its endpoints. You will need to create your own Auth0 API, which can be done for free and then set the appropriate environment variables, as shown below. By default, This option is turned off. You can set `auth.type: NONE` and use custom authentication methods at cluster level.


### Configuration

***

The following environment variables are used by the dscp-api. Entries marked as required are needed when running dscp-api in production mode.

| Variable                        | Required | Default                | Description                                                                                 |
|:------------------------------- | :------: | :--------------------: | :------------------------------------------------------------------------------------------ |
| PORT                            |    N     |         3001           | The port for the API to listen on                                                           |            
| API_HOST                        |    Y     |           -            | The hostname of the dscp-node to which the API should connect                               |
| API_PORT                        |    N     |         9944           | The port of the dscp-node to which the API should connect                                   |
| LOG_LEVEL                       |    N     |         info           | Logging level. Valid values are [trace, debug, info, warn, error, fatal]                    |      
| USER_URI                        |    Y     |           -            | The Substrate URI (representing the private key)  to use when making dscp-node transactions |
| IPFS_HOST                       |    Y     |           -            | Hostname of the IPFS node used for metadata storage                                         |
| IPFS_PORT                       |    N     |         15001          | Port of the IPFS node used for metadata storage                                             |
| METADATA_KEY_LENGTH             |    N     |           32           | Fixed length of metadata keys                                                               |
| METADATA_VALUE_LITERAL_LENGTH   |    N     |           32           | Fixed length of metadata LITERAL values                                                     |
| MAX_METADATA_COUNT              |    N     |          `16`          | Maximum number of metadata items allowed per token                                          |
| API_VERSION                     |    N     | `package.json version` | API version                                                                                 |
| API_MAJOR_VERSION               |    N     |          `v3`          | API major version                                                                           |
| FILE_UPLOAD_MAX_SIZE            |    N     |  `200 * 1024 * 1024`   | The Maximum file upload size (bytes)                                                        |
| SUBSTRATE_STATUS_POLL_PERIOD_MS |    N     |      `10 * 1000`       | Number of ms between calls to check dscp-node status                                        |
| SUBSTRATE_STATUS_TIMEOUT_MS     |    N     |       `2 * 1000`       | Number of ms to wait for response to dscp-node health requests                              |
| IPFS_STATUS_POLL_PERIOD_MS      |    N     |      `10 * 1000`       | Number of ms between calls to check ipfs status                                             |
| IPFS_STATUS_TIMEOUT_MS          |    N     |       `2 * 1000`       | Number of ms to wait for response to ipfs health requests                                   |
| AUTH_TYPE                       |    N     |         `NONE`         | Authentication type for routes on the service. Valid values: [`NONE`, `JWT`]                |

The following environment variables are additionally used when `AUTH_TYPE : 'JWT'`

| Variable       | Required |                       Default                       | Description                                                   |
| -------------- | -------- | --------------------------------------------------- | ------------------------------------------------------------- |
| AUTH_JWKS_URI  |    N     | `https://inteli.eu.auth0.com/.well-known/jwks.json` | JSON Web Key Set containing public keys used by the Auth0 API |
| AUTH_AUDIENCE  |    N     |                    `inteli-dev`                     | Identifier of the Auth0 API                                   |
| AUTH_ISSUER    |    N     |           `https://inteli.eu.auth0.com/`            | Domain of the Auth0 API                                       |

### *DSCP-Frontend Configuration Guide WIP*

***

### Deployment

***

1. Create a copy of the `network.yaml` you have used to set up your network.
2. For each organization, navigate to the `gitops` section and change the `chart_source` to `examples/dscp-app/charts`.
3. Deploy the dscp-app by executing the following command:
```
ansible-playbook examples/dscp-app/configuration/deploy-dscp-app.yaml -e "@/path/to/application/network.yaml"
```

### API specification

***

### Access token endpoint

### Authenticated endpoints

If `AUTH_TYPE` env is set to `JWT`, the rest of the endpoints in `dscp-api` require authentication in the form of a header `'Authorization: Bearer YOUR_ACCESS_TOKEN'`:

1. [GET /item/:id](#get-/item/:id)
2. [GET /item/:id/metadata/:metadataKey](#get-/item/:id/metadata/:metadataKey)
3. [POST /run-process](#POST-/run-process)
4. [GET /last-token](#get-/last-token)

### GET /item/:id

Gets the item identified by `id`. Item `id`s are returned by [POST /run-process](#post-/run-process). This will return a JSON response (`Content-Type` `application/json`) of the form:

```js
{
    "id": 42, // Number
    "original_id": 20, // Number
    "roles": {"Owner": "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY"}, // Object
    "creator": "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY", // String
    "created_at": 4321, // Number
    "destroyed_at": 4999, || null, // Nullable<Number>
    "parents": [40, 41], // Array<Number>
    "children": [43, 44] || null // Nullable<Array<Number>>
    "timestamp": "2022-02-09T10:30:12.003Z" // Date (ISO)
    "metadata_keys": ["metadataKey1", ..."metadataKeyN"] // Array<String>
 }
```

### GET /item/:id/metadata/:metadataKey

Gets the metadata value matching the `metadataKey` for the item identified by `id`. Item `id`s are returned by [POST /run-process](#post-/run-process). If the value is a string, it will be returned with a `Content-Type` of `text/plain`. If the value is a file, it will be returned with a `Content-Type` of `application/octet-stream`. The original `filename` is returned in the `Content-Disposition` header.

### POST /run-process

This endpoint governs the creation and destruction of all tokens in the system. The endpoint takes a `body` of a multi-part form constructed with a `request` field. The `request` field should be a JSON object with the following format:

```js
{
  "inputs": [40, 41] // Array<Number>,
  "outputs": [{ // Array<Output>
    "roles": {
      "Owner": "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY",
      ..."some_other_role_key": "some_account_id"
    },
    "metadata": {
      "some_file": { "type": "FILE", "value": "some_file.txt"},
      "some_literal": {"type": "LITERAL", "value": "some_value"},
      "some_token_id": {"type": "TOKEN_ID", "value": "42"},
      ..."metadataKeyN": {"type": "LITERAL", "value", "some_other_value"}
    },
    "parent_index": 0, // Number, optional
  }]
}
```

The `inputs` field is an array of token `id`s that identifies the tokens to be consumed by running this process. To create tokens without destroying any inputs simply pass an empty array. To destroy a token, the `AccountId` from the `USER_URI` of the sender must match the `AccountId` associated with the default (`Owner`) role for that token.

The `outputs` field is an array of objects that describe tokens to be created by running this process. To destroy tokens without creating any new ones simply pass an empty array. Each output must reference a `roles` object containing a (key, value) pair for each role associated with the new token. The value is the `AccountId` for the role. At minimum, a token requires the default `Owner` role to be set. The following role keys are accepted:

```json
["Owner", "Customer", "AdditiveManufacturer", "Laboratory", "Buyer", "Supplier", "Reviewer"]
```

Each output must also reference a `metadata` object containing a (key, value) pair for each metadata item associated with the new token. The following metadata value types are accepted:

```json
["FILE", "LITERAL", "TOKEN_ID", "NONE"]
```

The key identifies the metadata item, and the value is either a string value, or for files, a file path. Each file path must match a corresponding file attached to the request.

The changing state of an asset is tracked through multiple tokens using `original_id`. To update the state of an asset, a new output for the asset can be uniquely assigned to the input token that represents the latest state of the asset, meaning the new token has the same `original_id` as the now burned input token. This is achieved with the optional `parent_index` field, which takes a value of a single integer representing the index of the `inputs` that this output will be assigned to. If no `parent_index` is given, the token represents a new asset, and the `original_id` matches the token `id`.

The response of this API will be JSON (`Content-Type` `application/json`) of the following form

```json
[42, 43]
```

Each element of the array contains the `id` of the `output` that was described in the corresponding index of the `outputs` array.

### GET /last-token

Gets the `id` of the last item created by [POST /run-process](#post-/run-process). This will return a JSON response (`Content-Type` `application/json`) of the form:

```js
{
    "id": 5, // Number
}
```

### GET /members

Each element returned represents a member and their corresponding address in the following format:

```json
[
  {
    "address": "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY"
  }
]
```
