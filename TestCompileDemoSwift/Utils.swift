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
        default:
            strResult = "unknown error type";
            break;
        }
        return strResult;
    }
    
    class func ewallet_step2string(_ step: process_step) -> String {
        var szRet = "";
        
        switch (step) {
        case pstep_invalid:
            szRet = "invalid";
            break;
        case pstep_comm_enum_dev:
            szRet = "comm_enum_dev";
            break;
        case pstep_comm_open_dev:
            szRet = "comm_open_dev";
            break;
        case pstep_comm_close_dev:
            szRet = "comm_close_dev";
            break;
        case pstep_comm_get_devinfo:
            szRet = "comm_get_devinfo";
            break;
        case pstep_comm_dev_select:
            szRet = "comm_dev_select";
            break;
        case pstep_init_seed_gen:
            szRet = "init_seed_gen";
            break;
        case pstep_init_mne_show:
            szRet = "init_mne_show";
            break;
        case pstep_init_mne_confirm:
            szRet = "init_mne_confirm";
            break;
        case pstep_init_seed_import:
            szRet = "init_seed_import";
            break;
        case pstep_init_keypair_gen:
            szRet = "init_keypair_gen";
            break;
        case pstep_init_key_agree_init:
            szRet = "init_key_agree_init";
            break;
        case pstep_init_key_agree_update:
            szRet = "init_key_agree_update";
            break;
        case pstep_init_key_agree_final:
            szRet = "init_key_agree_final";
            break;
        case pstep_init_key_agree_show:
            szRet = "init_key_agree_show";
            break;
        case pstep_init_key_agree_confirm:
            szRet = "init_key_agree_confirm";
            break;
        case pstep_init_shamir_transmit_init:
            szRet = "init_shamir_transmit_init";
            break;
        case pstep_init_shamir_export:
            szRet = "init_shamir_export";
            break;
        case pstep_init_shamir_import:
            szRet = "init_shamir_import";
            break;
        case pstep_init_shamir_confirm:
            szRet = "init_shamir_confirm";
            break;
        case pstep_comm_addr_gen:
            szRet = "comm_addr_gen";
            break;
        case pstep_comm_shamir_transmit_init:
            szRet = "comm_shamir_transmit_init";
            break;
        case pstep_comm_shamir_export:
            szRet = "comm_shamir_export";
            break;
        case pstep_comm_shamir_import:
            szRet = "comm_shamir_import";
            break;
        case pstep_comm_addr_get:
            szRet = "comm_addr_get";
            break;
        case pstep_comm_addr_confirm:
            szRet = "comm_addr_confirm";
            break;
        case pstep_comm_format:
            szRet = "comm_format";
            break;
        case pstep_comm_format_confirm:
            szRet = "comm_format_confirm";
            break;
        case pstep_sig_output_data:
            szRet = "sig_output_data";
            break;
        case pstep_sig_confirm:
            szRet = "sig_confirm";
            break;
        case pstep_comm_clearcos:
            szRet = "comm_clearcos";
            break;
        case pstep_comm_clearcos_confirm:
            szRet = "comm_clearcos_confirm";
            break;
        case pstep_comm_updatecos:
            szRet = "comm_updatecos";
            break;
        case pstep_comm_changepin:
            szRet = "comm_changepin";
            break;
        case pstep_comm_changepin_confirm:
            szRet = "comm_changepin_confirm";
            break;
        default:
            szRet = "unknown";
            break;
        }
        return szRet;
    }
    
    class func ewallet_status2string(_ status: process_status) -> String {
        var szRet = "";
        
        switch (status) {
        case pstatus_invalid:
            szRet = "invalid";
            break;
        case pstatus_start:
            szRet = "start";
            break;
        case pstatus_finish:
            szRet = "finish";
            break;
        default:
            szRet = "unknown";
            break;
        }
        return szRet;
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
