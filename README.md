# BladeX_iOS_swift
This project shows how to use the **WOOKONG Bio** (internal code: **bladeX**) library on iOS with pure swift language

All the APIs are defined in PAEWallet.h with C-style.

_NOTE: All the method mentioned here should NOT be called in main thread, otherwise bluetooth
communication will be blocked._

## More details:
* [wiki: home](https://github.com/extropiescom/bladeX/wiki)
* [wiki: iOS API](https://github.com/extropiescom/bladeX/wiki/bladeX-iOS-API-list(For-hackathon))

## 1. How to connect and disconnect:
   - Invoke `PAEW_GetDeviceListWithDevContext` to get device name list, device names
   are in format of "device_name####device_address".
   - Use `PAEW_InitContextWithDevNameAndDevContext` to connect device, with devName
   chosen from `PAEW_GetDeviceListWithDevContext` result.
   - User `PAEW_FreeContext` or `PAEW_PowerOff` to disconnect
   and power down the device.
## 2. How to initialize device:
   - PIN initialize: If `PAEW_GetDevInfo` returns device info with `ucPINState == PAEW_DEV_INFO_PIN_UNSET`,
   this means PIN haven't been set, and you should call `MiddlewareInterface.initPIN()` to initialize.
   - Seed initialize: If `PAEW_InitPIN` returns device info with `ucLifeCycle == PAEW_DEV_INFO_LIFECYCLE_PRODUCE`,
   this means there're no seed inside device, and you should initialize device first (after device initialization, ucLifeCycle
   should be `PAEW_DEV_INFO_LIFECYCLE_USER`). Invoke `PAEW_GenerateSeed_GetMnes` + `PAEW_GenerateSeed_CheckMnes`
   to generate new seed, or invoke `PAEW_ImportSeed` to import mnemonics to import seed.
## 3. How to get EOS address:
   - Invoke `PAEW_DeriveTradeAddress`, with
   `derivePath = {0, 0x8000002C, 0x800000c2, 0x80000000, 0x00000000, 0x00000000}` according to [slip-44](https://github.com/satoshilabs/slips/blob/master/slip-0044.md).
   - Invoke `PAEW_GetTradeAddress` to get EOS address.
## 4. How to sign EOS transaction:
   - Invoke `PAEW_DeriveTradeAddress`, with
   `derivePath = {0, 0x8000002C, 0x800000c2, 0x80000000, 0x00000000, 0x00000000};` according to [slip-44](https://github.com/satoshilabs/slips/blob/master/slip-0044.md).
   - (Optional) Invoke `PAEW_EOS_TX_Serialize` to serialize json string to binary.
   
   _NOTE1: ref_block_prefix field of json object MUST be wrapped by quotation marks ("") if you pass it to `PAEW_EOS_TX_Serialize`, such as \"2642943355\" in the following._
   
   _NOTE2: serializeData is the binary form of transaction, you should prefix it with 32 bytes of chain_id, and padding with 32 bytes of zeros, then pass it to `PAEW_EOS_TXSign` to sign._
   
   ```c
   const char* jsonTxString = "{\"expiration\":\"2018-05-16T02:49:35\",\"ref_block_num\":4105,\"ref_block_prefix\":\"2642943355\",\"max_net_usage_words\":0,\"max_cpu_usage_ms\":0,\"delay_sec\":0,\"context_free_actions\":[],\"actions\":[{\"account\":\"eosio\",\"name\":\"newaccount\",\"authorization\":[{\"actor\":\"eosio\",\"permission\":\"active\"}],\"data\":\"0000000000ea30550000000000000e3d01000000010003224c02ca019e9c0c969d2c8006b89275abeeb5b05af68f2cf5f497bd6e1aff6d01000000010000000100038d424cbe81564f1e4338d342a4dc2b70d848d8b026d3f783bc7c8e6c3c6733cf01000000\"}],\"transaction_extensions\":[],\"signatures\":[],\"context_free_data\":[]}";
   unsigned char *pSerializeData = NULL;
   int serializeDataLen = 0;
   //get buffer size using serializeData = null
   iRtn = PAEW_EOS_TX_Serialize(jsonTxString, pSerializeData, &serializeDataLen);
   if (iRtn == PAEW_RET_SUCCESS) {
      //malloc buffer, remember to free it after use
      pSerializeData = (unsigned char *)malloc(serializeDataLen);
      //serialize transaction
      iRtn = PAEW_EOS_TX_Serialize(jsonTxString, pSerializeData, &serializeDataLen);
   }
   ```   
   - Invoke `PAEW_EOS_TXSign_Ex(void * const pPAEWContext, const size_t nDevIndex, const unsigned char * const pbCurrentTX, const size_t nCurrentTXLen, unsigned char * const pbTXSig, size_t * const pnTXSigLen, const signCallbacks * const pSignCallbacks, void * const pSignCallbackContext)`, 
   _this transaction is serialized result of a json transaction string, prefixed with chain_id (32 bytes) and tailed with zeros (32 bytes)_
   ```c
   unsigned char transaction[] = {0x74, 0x09, 0x70, 0xd9, 0xff, 0x01, 0xb5, 0x04, 0x63, 0x2f, 0xed, 0xe1, 0xad, 0xc3, 0xdf, 0xe5, 0x59, 0x90, 0x41, 0x5e, 0x4f, 0xde, 0x01, 0xe1, 0xb8, 0xf3, 0x15, 0xf8, 0x13, 0x6f, 0x47, 0x6c, 0x14, 0xc2, 0x67, 0x5b, 0x01, 0x24, 0x5f, 0x70, 0x5d, 0xd7, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0xa6, 0x82, 0x34, 0x03, 0xea, 0x30, 0x55, 0x00, 0x00, 0x00, 0x57, 0x2d, 0x3c, 0xcd, 0xcd, 0x01, 0x20, 0x29, 0xc2, 0xca, 0x55, 0x7a, 0x73, 0x57, 0x00, 0x00, 0x00, 0x00, 0xa8, 0xed, 0x32, 0x32, 0x21, 0x20, 0x29, 0xc2, 0xca, 0x55, 0x7a, 0x73, 0x57, 0x90, 0x55, 0x8c, 0x86, 0x77, 0x95, 0x4c, 0x3c, 0x10, 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x45, 0x4f, 0x53, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
   unsigned char signature[PAEW_EOS_SIG_MAX_LEN]= {0};
   int sigLen = PAEW_ETH_SIG_MAX_LEN;
   iRtn = PAEW_EOS_TXSign_Ex(pPAEWContext, 0, transaction, sizeof(transaction), signature, &sigLen, &signCallback, NULL);
   ```
## 5. Sign Callbacks
   
   _Sign callbacks are invoked in the following sequence:_
   - Invoke `MiddlewareInterface.getAuthResult()`, return `PAEW_RET_SUCCESS` or `PAEW_RET_DEV_OP_CANCEL`, indicates user chooses OK or Cancel on UI. If returns `PAEW_RET_SUCCESS`, signature will go on; if returns `PAEW_RET_DEV_OP_CANCE`L, you should call `abort()` to end this sign procedure.
   - Invoke `MiddlewareInterface.getAuthType()`, return `PAEW_SIGN_AUTH_TYPE_PIN` or `PAEW_SIGN_AUTH_TYPE_FP`.
   - If `MiddlewareInterface.getAuthType()` returns `PAEW_SIGN_AUTH_TYPE_PIN`, then call `MiddlewareInterface.getPINResult()`. `MiddlewareInterface.getPINResult()` returns `PAEW_RET_SUCCESS` or `PAEW_RET_DEV_OP_CANCEL`, indicates user choosesOK or Cancel on UI.If returns` PAEW_RET_SUCCES`S, signature will go on; if returns `PAEW_RET_DEV_OP_CANCEL`, you should call `abort()` to end this sign procedure.
   - If `MiddlewareInterface.getAuthType()` returns `PAEW_SIGN_AUTH_TYPE_PIN`, and `MiddlewareInterface.getPINResult()` returns `PAEW_RET_SUCCESS`, then call `MiddlewareInterface.getPIN()` to get PIN from UI.
   - Do signature according to user's option.
   - pseudo-code of signature method
```C
if (PAEW_RET_SUCCESS != getAuthType (&nAuthType)) {
    return;
}

if (PAEW_SIGN_AUTH_TYPE_PIN == nAuthType) {
    if (PAEW_RET_SUCCESS != getPIN (szPIN)) {
        return;
    }
}

nResult = (do_signature_with_user_selected_authenticate_type_(fingerprint_or_PIN))

if ((PAEW_RET_SUCCESS != nResult) && (PAEW_SIGN_AUTH_TYPE_PIN != nAuthType)) {
    if (PAEW_RET_SUCCESS != getPIN (szPIN)) {
        return;
    }
    (do_signature_with_PIN_authority())
}
```
