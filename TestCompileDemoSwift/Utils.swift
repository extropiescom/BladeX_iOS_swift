//
//  Utils.swift
//  TestCompileDemoSwift
//
//  Created by Peng Wei on 2018/11/1.
//  Copyright © 2018年 extropies. All rights reserved.
//

import UIKit

class Utils: NSObject {
    
    class func errorCodeToString(_ retValue:Int32) -> String {
        let code:UInt32 = UInt32(bitPattern: retValue)
        return errorCodeToString(code)
    }
    
    //a helper function to transform error code into text
    class func errorCodeToString(_ retValue:UInt32) -> String {
        var strResult = "unknown error";
        switch (retValue) {
            
        case UInt32(PAEW_RET_SUCCESS):
            strResult = "success";
            break;
        case PAEW_RET_UNKNOWN_FAIL:
            strResult="unknown error";
            break;
        case PAEW_RET_ARGUMENTBAD:
            strResult="argument bad";
            break;
        case PAEW_RET_HOST_MEMORY:
            strResult="host memory error";
            break;
        case PAEW_RET_DEV_ENUM_FAIL:
            strResult="device enum failed";
            break;
        case PAEW_RET_DEV_OPEN_FAIL:
            strResult="device open failed";
            break;
        case PAEW_RET_DEV_COMMUNICATE_FAIL:
            strResult="device communicate failed";
            break;
        case PAEW_RET_DEV_NEED_PIN:
            strResult="need pin error";
            break;
        case PAEW_RET_DEV_OP_CANCEL:
            strResult="device operation cancelled";
            break;
        case PAEW_RET_DEV_KEY_NOT_RESTORED:
            strResult="device key not restored";
            break;
        case PAEW_RET_DEV_KEY_ALREADY_RESTORED:
            strResult="device key already restored";
            break;
        case PAEW_RET_DEV_COUNT_BAD:
            strResult="device count bad";
            break;
        case PAEW_RET_DEV_RETDATA_INVALID:
            strResult="device returned data invalid";
            break;
        case PAEW_RET_DEV_AUTH_FAIL:
            strResult="device authentication failed";
            break;
        case PAEW_RET_DEV_STATE_INVALID:
            strResult="device state invalid";
            break;
        case PAEW_RET_DEV_WAITING:
            strResult="device waiting";
            break;
        case PAEW_RET_DEV_COMMAND_INVALID:
            strResult="command invalid";
            break;
        case PAEW_RET_DEV_RUN_COMMAND_FAIL:
            strResult="run command failed";
            break;
        case PAEW_RET_DEV_HANDLE_INVALID:
            strResult="device handle invalid";
            break;
        case PAEW_RET_COS_TYPE_INVALID:
            strResult="FW type invalid";
            break;
        case PAEW_RET_COS_TYPE_NOT_MATCH:
            strResult="FW type not match";
            break;
        case PAEW_RET_DEV_BAD_SHAMIR_SPLIT:
            strResult="bad shamir split";
            break;
        case PAEW_RET_DEV_NOT_ONE_GROUP:
            strResult="device not one group";
            break;
        case PAEW_RET_BUFFER_TOO_SAMLL:
            strResult="buffer too small";
            break;
        case PAEW_RET_TX_PARSE_FAIL:
            strResult="transaction parsed error";
            break;
        case PAEW_RET_TX_UTXO_NEQ:
            strResult="UTXO not equal to INPUT count";
            break;
        case PAEW_RET_TX_INPUT_TOO_MANY:
            strResult="transaction INPUT too many";
            break;
        case PAEW_RET_MUTEX_ERROR:
            strResult="mutex error";
            break;
        case PAEW_RET_COIN_TYPE_INVALID:
            strResult="coin type invalid";
            break;
        case PAEW_RET_COIN_TYPE_NOT_MATCH:
            strResult="coin type not match";
            break;
        case PAEW_RET_DERIVE_PATH_INVALID:
            strResult="derive path invalid";
            break;
        case PAEW_RET_NOT_SUPPORTED:
            strResult="call not supported";
            break;
        case PAEW_RET_INTERNAL_ERROR:
            strResult="internal error";
            break;
        case PAEW_RET_BAD_N_T:
            strResult="invalid N or T";
            break;
        case PAEW_RET_TARGET_DEV_INVALID:
            strResult="target device invalid";
            break;
        case PAEW_RET_CRYPTO_ERROR:
            strResult="crypto error";
            break;
        case PAEW_RET_DEV_TIMEOUT:
            strResult="timeout";
            break;
        case PAEW_RET_DEV_PIN_LOCKED:
            strResult="PIN locked";
            break;
        case PAEW_RET_DEV_PIN_CONFIRM_FAIL:
            strResult="PIN confirm failed";
            break;
        case PAEW_RET_DEV_PIN_VERIFY_FAIL:
            strResult="PIN verify failed";
            break;
        case PAEW_RET_DEV_CHECKDATA_FAIL:
            strResult="device check data failed";
            break;
        case PAEW_RET_DEV_DEV_OPERATING:
            strResult="device is on operating";
            break;
        case PAEW_RET_DEV_PIN_UNINIT:
            strResult="PIN not inited";
            break;
        case PAEW_RET_DEV_BUSY:
            strResult="device busy";
            break;
        case PAEW_RET_DEV_ALREADY_AVAILABLE:
            strResult="device already available, don't need to abort";
            break;
        case PAEW_RET_DEV_DATA_NOT_FOUND:
            strResult="device data not found";
            break;
        case PAEW_RET_DEV_SENSOR_ERROR:
            strResult="device sensor error";
            break;
        case PAEW_RET_DEV_STORAGE_ERROR:
            strResult="device storage error";
            break;
        case PAEW_RET_DEV_STORAGE_FULL:
            strResult="device storage full";
            break;
        case PAEW_RET_DEV_FP_COMMON_ERROR:
            strResult="finger print command error";
            break;
        case PAEW_RET_DEV_FP_REDUNDANT:
            strResult="redundant fingerprint";
            break;
        case PAEW_RET_DEV_FP_GOOG_FINGER:
            strResult="good fingerprint";
            break;
        case PAEW_RET_DEV_FP_NO_FINGER:
            strResult="not fingerprint";
            break;
        case PAEW_RET_DEV_FP_NOT_FULL_FINGER:
            strResult="not full fingerprint";
            break;
        case PAEW_RET_DEV_FP_BAD_IMAGE:
            strResult="bad fingerprint image";
            break;
        case PAEW_RET_DEV_LOW_POWER:
            strResult="device low power";
            break;
        case PAEW_RET_DEV_TYPE_INVALID:
            strResult="device type invalid";
            break;
        case PAEW_RET_NO_VERIFY_COUNT:
            strResult="no verify count";
            break;
        case PAEW_RET_AUTH_CANCEL:
            strResult="auth cancelled";
            break;
        case PAEW_RET_PIN_LEN_ERROR:
            strResult="pin length error";
            break;
        case PAEW_RET_AUTH_TYPE_INVALID:
            strResult="auth type invalid";
            break;
        default:
            strResult = "unknown error type";
            break;
        }
        return strResult;
    }
    
    class func bytesToHexString(data: Data) -> String {
        let length: size_t = data.count;
        return bytesToHexString(data: data, length: length)
    }
    
    class func bytesToHexString(data: Data, length: size_t) -> String {
        guard length <= data.count else {
            return ""
        }
        let ptr = data.withUnsafeBytes { (ptr: UnsafePointer<byte>) -> UnsafePointer<byte> in
            return ptr
        }
        return bytesToHexString(data: ptr, length: length)
    }
    
    class func bytesToHexString(data: UnsafePointer<byte>, length: size_t) -> String {
        let result: NSMutableString = ""
        for i in 0..<length {
            result.appendFormat("%02X", data.advanced(by: i).pointee)
        }
        return result as String
    }
    
    class func bytesToHexString(data: [byte]) -> String {
        let hexData = Data.init(bytes: data)
        return bytesToHexString(data: hexData)
    }
    
    class func bytesToHexString(data: [byte], length: size_t) -> String {
        let hexData = Data.init(bytes: data[0..<length])
        return bytesToHexString(data: hexData)
    }
    
    class func hexStringToBytes(hexString: String) -> Data? {
        let length: size_t = hexString.count
        if (length % 2 != 0) {
            return nil;
        }
        var data: Data = Data.init()
        for i in 0..<length/2 {
            var anInt:UInt32 = 0
            let b: byte
            let hexCharStr:String = String(hexString[hexString.index(hexString.startIndex, offsetBy: 2*i)..<hexString.index(hexString.startIndex, offsetBy: 2*i+2)])
            let scanner: Scanner = Scanner.init(string: hexCharStr)
            scanner.scanHexInt32(&anInt)
            b = byte(anInt)
            data.append(b)
        }
        return data
    }
}
