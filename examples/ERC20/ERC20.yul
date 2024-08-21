/// @use-src 0:"examples/ERC20/ERC20.sol"
object "ERC20_194" {
    code {
        /// @src 0:58:1653  "contract ERC20 {..."
        mstore(64, memoryguard(128))
        if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }

        constructor_ERC20_194()

        let _1 := allocate_unbounded()
        codecopy(_1, dataoffset("ERC20_194_deployed"), datasize("ERC20_194_deployed"))

        return(_1, datasize("ERC20_194_deployed"))

        function allocate_unbounded() -> memPtr {
            memPtr := mload(64)
        }

        function revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() {
            revert(0, 0)
        }

        /// @src 0:58:1653  "contract ERC20 {..."
        function constructor_ERC20_194() {

            /// @src 0:58:1653  "contract ERC20 {..."

        }
        /// @src 0:58:1653  "contract ERC20 {..."

    }
    /// @use-src 0:"examples/ERC20/ERC20.sol"
    object "ERC20_194_deployed" {
        code {
            /// @src 0:58:1653  "contract ERC20 {..."
            mstore(64, memoryguard(128))

            if iszero(lt(calldatasize(), 4))
            {
                let selector := shift_right_224_unsigned(calldataload(0))
                switch selector

                case 0x06fdde03
                {
                    // name()

                    external_fun_name_32()
                }

                case 0x095ea7b3
                {
                    // approve(address,uint256)

                    external_fun_approve_98()
                }

                case 0x18160ddd
                {
                    // totalSupply()

                    external_fun_totalSupply_19()
                }

                case 0x23b872dd
                {
                    // transferFrom(address,address,uint256)

                    external_fun_transferFrom_139()
                }

                case 0x313ce567
                {
                    // decimals()

                    external_fun_decimals_38()
                }

                case 0x42966c68
                {
                    // burn(uint256)

                    external_fun_burn_193()
                }

                case 0x70a08231
                {
                    // balanceOf(address)

                    external_fun_balanceOf_23()
                }

                case 0x95d89b41
                {
                    // symbol()

                    external_fun_symbol_35()
                }

                case 0xa0712d68
                {
                    // mint(uint256)

                    external_fun_mint_166()
                }

                case 0xa9059cbb
                {
                    // transfer(address,uint256)

                    external_fun_transfer_70()
                }

                case 0xdd62ed3e
                {
                    // allowance(address,address)

                    external_fun_allowance_29()
                }

                default {}
            }

            revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74()

            function shift_right_224_unsigned(value) -> newValue {
                newValue :=

                shr(224, value)

            }

            function allocate_unbounded() -> memPtr {
                memPtr := mload(64)
            }

            function revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() {
                revert(0, 0)
            }

            function revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() {
                revert(0, 0)
            }

            function abi_decode_tuple_(headStart, dataEnd)   {
                if slt(sub(dataEnd, headStart), 0) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

            }

            function round_up_to_mul_of_32(value) -> result {
                result := and(add(value, 31), not(31))
            }

            function panic_error_0x41() {
                mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
                mstore(4, 0x41)
                revert(0, 0x24)
            }

            function finalize_allocation(memPtr, size) {
                let newFreePtr := add(memPtr, round_up_to_mul_of_32(size))
                // protect against overflow
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr)) { panic_error_0x41() }
                mstore(64, newFreePtr)
            }

            function allocate_memory(size) -> memPtr {
                memPtr := allocate_unbounded()
                finalize_allocation(memPtr, size)
            }

            function array_allocation_size_t_string_memory_ptr(length) -> size {
                // Make sure we can allocate memory without overflow
                if gt(length, 0xffffffffffffffff) { panic_error_0x41() }

                size := round_up_to_mul_of_32(length)

                // add length slot
                size := add(size, 0x20)

            }

            function allocate_memory_array_t_string_memory_ptr(length) -> memPtr {
                let allocSize := array_allocation_size_t_string_memory_ptr(length)
                memPtr := allocate_memory(allocSize)

                mstore(memPtr, length)

            }

            function store_literal_in_memory_83a17a3f185603d588748a162a53d4a69b64af5061f5edc1eb131a3f0a47b31d(memPtr) {

                mstore(add(memPtr, 0), "Solidity by Example")

            }

            function copy_literal_to_memory_83a17a3f185603d588748a162a53d4a69b64af5061f5edc1eb131a3f0a47b31d() -> memPtr {
                memPtr := allocate_memory_array_t_string_memory_ptr(19)
                store_literal_in_memory_83a17a3f185603d588748a162a53d4a69b64af5061f5edc1eb131a3f0a47b31d(add(memPtr, 32))
            }

            function convert_t_stringliteral_83a17a3f185603d588748a162a53d4a69b64af5061f5edc1eb131a3f0a47b31d_to_t_string_memory_ptr() -> converted {
                converted := copy_literal_to_memory_83a17a3f185603d588748a162a53d4a69b64af5061f5edc1eb131a3f0a47b31d()
            }

            /// @src 0:376:427  "string constant public name = \"Solidity by Example\""
            function constant_name_32() -> ret_mpos {
                /// @src 0:406:427  "\"Solidity by Example\""
                let _1_mpos := convert_t_stringliteral_83a17a3f185603d588748a162a53d4a69b64af5061f5edc1eb131a3f0a47b31d_to_t_string_memory_ptr()

                ret_mpos := _1_mpos
            }

            /// @ast-id 32
            /// @src 0:376:427  "string constant public name = \"Solidity by Example\""
            function getter_fun_name_32() -> ret_0 {
                ret_0 := constant_name_32()
            }
            /// @src 0:58:1653  "contract ERC20 {..."

            function array_length_t_string_memory_ptr(value) -> length {

                length := mload(value)

            }

            function array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, length) -> updated_pos {
                mstore(pos, length)
                updated_pos := add(pos, 0x20)
            }

            function copy_memory_to_memory_with_cleanup(src, dst, length) {
                let i := 0
                for { } lt(i, length) { i := add(i, 32) }
                {
                    mstore(add(dst, i), mload(add(src, i)))
                }
                mstore(add(dst, length), 0)
            }

            function abi_encode_t_string_memory_ptr_to_t_string_memory_ptr_fromStack(value, pos) -> end {
                let length := array_length_t_string_memory_ptr(value)
                pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, length)
                copy_memory_to_memory_with_cleanup(add(value, 0x20), pos, length)
                end := add(pos, round_up_to_mul_of_32(length))
            }

            function abi_encode_tuple_t_string_memory_ptr__to_t_string_memory_ptr__fromStack(headStart , value0) -> tail {
                tail := add(headStart, 32)

                mstore(add(headStart, 0), sub(tail, headStart))
                tail := abi_encode_t_string_memory_ptr_to_t_string_memory_ptr_fromStack(value0,  tail)

            }

            function external_fun_name_32() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                abi_decode_tuple_(4, calldatasize())
                let ret_0 :=  getter_fun_name_32()
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple_t_string_memory_ptr__to_t_string_memory_ptr__fromStack(memPos , ret_0)
                return(memPos, sub(memEnd, memPos))

            }

            function revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db() {
                revert(0, 0)
            }

            function cleanup_t_uint160(value) -> cleaned {
                cleaned := and(value, 0xffffffffffffffffffffffffffffffffffffffff)
            }

            function cleanup_t_address(value) -> cleaned {
                cleaned := cleanup_t_uint160(value)
            }

            function validator_revert_t_address(value) {
                if iszero(eq(value, cleanup_t_address(value))) { revert(0, 0) }
            }

            function abi_decode_t_address(offset, end) -> value {
                value := calldataload(offset)
                validator_revert_t_address(value)
            }

            function cleanup_t_uint256(value) -> cleaned {
                cleaned := value
            }

            function validator_revert_t_uint256(value) {
                if iszero(eq(value, cleanup_t_uint256(value))) { revert(0, 0) }
            }

            function abi_decode_t_uint256(offset, end) -> value {
                value := calldataload(offset)
                validator_revert_t_uint256(value)
            }

            function abi_decode_tuple_t_addresst_uint256(headStart, dataEnd) -> value0, value1 {
                if slt(sub(dataEnd, headStart), 64) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

                {

                    let offset := 0

                    value0 := abi_decode_t_address(add(headStart, offset), dataEnd)
                }

                {

                    let offset := 32

                    value1 := abi_decode_t_uint256(add(headStart, offset), dataEnd)
                }

            }

            function cleanup_t_bool(value) -> cleaned {
                cleaned := iszero(iszero(value))
            }

            function abi_encode_t_bool_to_t_bool_fromStack(value, pos) {
                mstore(pos, cleanup_t_bool(value))
            }

            function abi_encode_tuple_t_bool__to_t_bool__fromStack(headStart , value0) -> tail {
                tail := add(headStart, 32)

                abi_encode_t_bool_to_t_bool_fromStack(value0,  add(headStart, 0))

            }

            function external_fun_approve_98() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                let param_0, param_1 :=  abi_decode_tuple_t_addresst_uint256(4, calldatasize())
                let ret_0 :=  fun_approve_98(param_0, param_1)
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple_t_bool__to_t_bool__fromStack(memPos , ret_0)
                return(memPos, sub(memEnd, memPos))

            }

            function shift_right_unsigned_dynamic(bits, value) -> newValue {
                newValue :=

                shr(bits, value)

            }

            function cleanup_from_storage_t_uint256(value) -> cleaned {
                cleaned := value
            }

            function extract_from_storage_value_dynamict_uint256(slot_value, offset) -> value {
                value := cleanup_from_storage_t_uint256(shift_right_unsigned_dynamic(mul(offset, 8), slot_value))
            }

            function read_from_storage_split_dynamic_t_uint256(slot, offset) -> value {
                value := extract_from_storage_value_dynamict_uint256(sload(slot), offset)

            }

            /// @ast-id 19
            /// @src 0:233:256  "uint public totalSupply"
            function getter_fun_totalSupply_19() -> ret {

                let slot := 0
                let offset := 0

                ret := read_from_storage_split_dynamic_t_uint256(slot, offset)

            }
            /// @src 0:58:1653  "contract ERC20 {..."

            function abi_encode_t_uint256_to_t_uint256_fromStack(value, pos) {
                mstore(pos, cleanup_t_uint256(value))
            }

            function abi_encode_tuple_t_uint256__to_t_uint256__fromStack(headStart , value0) -> tail {
                tail := add(headStart, 32)

                abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

            }

            function external_fun_totalSupply_19() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                abi_decode_tuple_(4, calldatasize())
                let ret_0 :=  getter_fun_totalSupply_19()
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple_t_uint256__to_t_uint256__fromStack(memPos , ret_0)
                return(memPos, sub(memEnd, memPos))

            }

            function abi_decode_tuple_t_addresst_addresst_uint256(headStart, dataEnd) -> value0, value1, value2 {
                if slt(sub(dataEnd, headStart), 96) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

                {

                    let offset := 0

                    value0 := abi_decode_t_address(add(headStart, offset), dataEnd)
                }

                {

                    let offset := 32

                    value1 := abi_decode_t_address(add(headStart, offset), dataEnd)
                }

                {

                    let offset := 64

                    value2 := abi_decode_t_uint256(add(headStart, offset), dataEnd)
                }

            }

            function external_fun_transferFrom_139() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                let param_0, param_1, param_2 :=  abi_decode_tuple_t_addresst_addresst_uint256(4, calldatasize())
                let ret_0 :=  fun_transferFrom_139(param_0, param_1, param_2)
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple_t_bool__to_t_bool__fromStack(memPos , ret_0)
                return(memPos, sub(memEnd, memPos))

            }

            function cleanup_t_rational_18_by_1(value) -> cleaned {
                cleaned := value
            }

            function cleanup_t_uint8(value) -> cleaned {
                cleaned := and(value, 0xff)
            }

            function identity(value) -> ret {
                ret := value
            }

            function convert_t_rational_18_by_1_to_t_uint8(value) -> converted {
                converted := cleanup_t_uint8(identity(cleanup_t_rational_18_by_1(value)))
            }

            /// @src 0:480:515  "uint8 constant public decimals = 18"
            function constant_decimals_38() -> ret {
                /// @src 0:513:515  "18"
                let expr_37 := 0x12
                let _2 := convert_t_rational_18_by_1_to_t_uint8(expr_37)

                ret := _2
            }

            /// @ast-id 38
            /// @src 0:480:515  "uint8 constant public decimals = 18"
            function getter_fun_decimals_38() -> ret_0 {
                ret_0 := constant_decimals_38()
            }
            /// @src 0:58:1653  "contract ERC20 {..."

            function abi_encode_t_uint8_to_t_uint8_fromStack(value, pos) {
                mstore(pos, cleanup_t_uint8(value))
            }

            function abi_encode_tuple_t_uint8__to_t_uint8__fromStack(headStart , value0) -> tail {
                tail := add(headStart, 32)

                abi_encode_t_uint8_to_t_uint8_fromStack(value0,  add(headStart, 0))

            }

            function external_fun_decimals_38() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                abi_decode_tuple_(4, calldatasize())
                let ret_0 :=  getter_fun_decimals_38()
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple_t_uint8__to_t_uint8__fromStack(memPos , ret_0)
                return(memPos, sub(memEnd, memPos))

            }

            function abi_decode_tuple_t_uint256(headStart, dataEnd) -> value0 {
                if slt(sub(dataEnd, headStart), 32) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

                {

                    let offset := 0

                    value0 := abi_decode_t_uint256(add(headStart, offset), dataEnd)
                }

            }

            function abi_encode_tuple__to__fromStack(headStart ) -> tail {
                tail := add(headStart, 0)

            }

            function external_fun_burn_193() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                let param_0 :=  abi_decode_tuple_t_uint256(4, calldatasize())
                fun_burn_193(param_0)
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple__to__fromStack(memPos  )
                return(memPos, sub(memEnd, memPos))

            }

            function abi_decode_tuple_t_address(headStart, dataEnd) -> value0 {
                if slt(sub(dataEnd, headStart), 32) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

                {

                    let offset := 0

                    value0 := abi_decode_t_address(add(headStart, offset), dataEnd)
                }

            }

            function convert_t_uint160_to_t_uint160(value) -> converted {
                converted := cleanup_t_uint160(identity(cleanup_t_uint160(value)))
            }

            function convert_t_uint160_to_t_address(value) -> converted {
                converted := convert_t_uint160_to_t_uint160(value)
            }

            function convert_t_address_to_t_address(value) -> converted {
                converted := convert_t_uint160_to_t_address(value)
            }

            function mapping_index_access_t_mapping$_t_address_$_t_uint256_$_of_t_address(slot , key) -> dataSlot {
                mstore(0, convert_t_address_to_t_address(key))
                mstore(0x20, slot)
                dataSlot := keccak256(0, 0x40)
            }

            /// @ast-id 23
            /// @src 0:262:303  "mapping(address => uint) public balanceOf"
            function getter_fun_balanceOf_23(key_0) -> ret {

                let slot := 1
                let offset := 0

                slot := mapping_index_access_t_mapping$_t_address_$_t_uint256_$_of_t_address(slot, key_0)

                ret := read_from_storage_split_dynamic_t_uint256(slot, offset)

            }
            /// @src 0:58:1653  "contract ERC20 {..."

            function external_fun_balanceOf_23() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                let param_0 :=  abi_decode_tuple_t_address(4, calldatasize())
                let ret_0 :=  getter_fun_balanceOf_23(param_0)
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple_t_uint256__to_t_uint256__fromStack(memPos , ret_0)
                return(memPos, sub(memEnd, memPos))

            }

            function store_literal_in_memory_0f476af2d5141cb726521d336ca71a33f2ee2c48e6402a2d48c2e06e9091f794(memPtr) {

                mstore(add(memPtr, 0), "SOLBYEX")

            }

            function copy_literal_to_memory_0f476af2d5141cb726521d336ca71a33f2ee2c48e6402a2d48c2e06e9091f794() -> memPtr {
                memPtr := allocate_memory_array_t_string_memory_ptr(7)
                store_literal_in_memory_0f476af2d5141cb726521d336ca71a33f2ee2c48e6402a2d48c2e06e9091f794(add(memPtr, 32))
            }

            function convert_t_stringliteral_0f476af2d5141cb726521d336ca71a33f2ee2c48e6402a2d48c2e06e9091f794_to_t_string_memory_ptr() -> converted {
                converted := copy_literal_to_memory_0f476af2d5141cb726521d336ca71a33f2ee2c48e6402a2d48c2e06e9091f794()
            }

            /// @src 0:433:474  "string constant public symbol = \"SOLBYEX\""
            function constant_symbol_35() -> ret_mpos {
                /// @src 0:465:474  "\"SOLBYEX\""
                let _3_mpos := convert_t_stringliteral_0f476af2d5141cb726521d336ca71a33f2ee2c48e6402a2d48c2e06e9091f794_to_t_string_memory_ptr()

                ret_mpos := _3_mpos
            }

            /// @ast-id 35
            /// @src 0:433:474  "string constant public symbol = \"SOLBYEX\""
            function getter_fun_symbol_35() -> ret_0 {
                ret_0 := constant_symbol_35()
            }
            /// @src 0:58:1653  "contract ERC20 {..."

            function external_fun_symbol_35() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                abi_decode_tuple_(4, calldatasize())
                let ret_0 :=  getter_fun_symbol_35()
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple_t_string_memory_ptr__to_t_string_memory_ptr__fromStack(memPos , ret_0)
                return(memPos, sub(memEnd, memPos))

            }

            function external_fun_mint_166() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                let param_0 :=  abi_decode_tuple_t_uint256(4, calldatasize())
                fun_mint_166(param_0)
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple__to__fromStack(memPos  )
                return(memPos, sub(memEnd, memPos))

            }

            function external_fun_transfer_70() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                let param_0, param_1 :=  abi_decode_tuple_t_addresst_uint256(4, calldatasize())
                let ret_0 :=  fun_transfer_70(param_0, param_1)
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple_t_bool__to_t_bool__fromStack(memPos , ret_0)
                return(memPos, sub(memEnd, memPos))

            }

            function abi_decode_tuple_t_addresst_address(headStart, dataEnd) -> value0, value1 {
                if slt(sub(dataEnd, headStart), 64) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

                {

                    let offset := 0

                    value0 := abi_decode_t_address(add(headStart, offset), dataEnd)
                }

                {

                    let offset := 32

                    value1 := abi_decode_t_address(add(headStart, offset), dataEnd)
                }

            }

            function mapping_index_access_t_mapping$_t_address_$_t_mapping$_t_address_$_t_uint256_$_$_of_t_address(slot , key) -> dataSlot {
                mstore(0, convert_t_address_to_t_address(key))
                mstore(0x20, slot)
                dataSlot := keccak256(0, 0x40)
            }

            /// @ast-id 29
            /// @src 0:309:370  "mapping(address => mapping(address => uint)) public allowance"
            function getter_fun_allowance_29(key_0, key_1) -> ret {

                let slot := 2
                let offset := 0

                slot := mapping_index_access_t_mapping$_t_address_$_t_mapping$_t_address_$_t_uint256_$_$_of_t_address(slot, key_0)

                slot := mapping_index_access_t_mapping$_t_address_$_t_uint256_$_of_t_address(slot, key_1)

                ret := read_from_storage_split_dynamic_t_uint256(slot, offset)

            }
            /// @src 0:58:1653  "contract ERC20 {..."

            function external_fun_allowance_29() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                let param_0, param_1 :=  abi_decode_tuple_t_addresst_address(4, calldatasize())
                let ret_0 :=  getter_fun_allowance_29(param_0, param_1)
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple_t_uint256__to_t_uint256__fromStack(memPos , ret_0)
                return(memPos, sub(memEnd, memPos))

            }

            function revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74() {
                revert(0, 0)
            }

            function zero_value_for_split_t_bool() -> ret {
                ret := 0
            }

            function shift_left_0(value) -> newValue {
                newValue :=

                shl(0, value)

            }

            function update_byte_slice_32_shift_0(value, toInsert) -> result {
                let mask := 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                toInsert := shift_left_0(toInsert)
                value := and(value, not(mask))
                result := or(value, and(toInsert, mask))
            }

            function convert_t_uint256_to_t_uint256(value) -> converted {
                converted := cleanup_t_uint256(identity(cleanup_t_uint256(value)))
            }

            function prepare_store_t_uint256(value) -> ret {
                ret := value
            }

            function update_storage_value_offset_0t_uint256_to_t_uint256(slot, value_0) {
                let convertedValue_0 := convert_t_uint256_to_t_uint256(value_0)
                sstore(slot, update_byte_slice_32_shift_0(sload(slot), prepare_store_t_uint256(convertedValue_0)))
            }

            /// @ast-id 98
            /// @src 0:765:965  "function approve(address spender, uint amount) external returns (bool) {..."
            function fun_approve_98(var_spender_72, var_amount_74) -> var__77 {
                /// @src 0:830:834  "bool"
                let zero_t_bool_4 := zero_value_for_split_t_bool()
                var__77 := zero_t_bool_4

                /// @src 0:879:885  "amount"
                let _5 := var_amount_74
                let expr_85 := _5
                /// @src 0:846:855  "allowance"
                let _6_slot := 0x02
                let expr_79_slot := _6_slot
                /// @src 0:856:866  "msg.sender"
                let expr_81 := caller()
                /// @src 0:846:867  "allowance[msg.sender]"
                let _7 := mapping_index_access_t_mapping$_t_address_$_t_mapping$_t_address_$_t_uint256_$_$_of_t_address(expr_79_slot,expr_81)
                let _8_slot := _7
                let expr_83_slot := _8_slot
                /// @src 0:868:875  "spender"
                let _9 := var_spender_72
                let expr_82 := _9
                /// @src 0:846:876  "allowance[msg.sender][spender]"
                let _10 := mapping_index_access_t_mapping$_t_address_$_t_uint256_$_of_t_address(expr_83_slot,expr_82)
                /// @src 0:846:885  "allowance[msg.sender][spender] = amount"
                update_storage_value_offset_0t_uint256_to_t_uint256(_10, expr_85)
                let expr_86 := expr_85
                /// @src 0:909:919  "msg.sender"
                let expr_90 := caller()
                /// @src 0:921:928  "spender"
                let _11 := var_spender_72
                let expr_91 := _11
                /// @src 0:930:936  "amount"
                let _12 := var_amount_74
                let expr_92 := _12
                /// @src 0:900:937  "Approval(msg.sender, spender, amount)"
                let _13 := 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
                let _14 := convert_t_address_to_t_address(expr_90)
                let _15 := convert_t_address_to_t_address(expr_91)
                {
                    let _16 := allocate_unbounded()
                    let _17 := abi_encode_tuple_t_uint256__to_t_uint256__fromStack(_16 , expr_92)
                    log3(_16, sub(_17, _16) , _13, _14, _15)
                }/// @src 0:954:958  "true"
                let expr_95 := 0x01
                /// @src 0:947:958  "return true"
                var__77 := expr_95
                leave

            }
            /// @src 0:58:1653  "contract ERC20 {..."

            function shift_right_0_unsigned(value) -> newValue {
                newValue :=

                shr(0, value)

            }

            function extract_from_storage_value_offset_0t_uint256(slot_value) -> value {
                value := cleanup_from_storage_t_uint256(shift_right_0_unsigned(slot_value))
            }

            function read_from_storage_split_offset_0_t_uint256(slot) -> value {
                value := extract_from_storage_value_offset_0t_uint256(sload(slot))

            }

            function panic_error_0x11() {
                mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
                mstore(4, 0x11)
                revert(0, 0x24)
            }

            function checked_sub_t_uint256(x, y) -> diff {
                x := cleanup_t_uint256(x)
                y := cleanup_t_uint256(y)
                diff := sub(x, y)

                if gt(diff, x) { panic_error_0x11() }

            }

            function checked_add_t_uint256(x, y) -> sum {
                x := cleanup_t_uint256(x)
                y := cleanup_t_uint256(y)
                sum := add(x, y)

                if gt(x, sum) { panic_error_0x11() }

            }

            /// @ast-id 139
            /// @src 0:971:1299  "function transferFrom(..."
            function fun_transferFrom_139(var_sender_100, var_recipient_102, var_amount_104) -> var__107 {
                /// @src 0:1089:1093  "bool"
                let zero_t_bool_18 := zero_value_for_split_t_bool()
                var__107 := zero_t_bool_18

                /// @src 0:1138:1144  "amount"
                let _19 := var_amount_104
                let expr_115 := _19
                /// @src 0:1105:1114  "allowance"
                let _20_slot := 0x02
                let expr_109_slot := _20_slot
                /// @src 0:1115:1121  "sender"
                let _21 := var_sender_100
                let expr_110 := _21
                /// @src 0:1105:1122  "allowance[sender]"
                let _22 := mapping_index_access_t_mapping$_t_address_$_t_mapping$_t_address_$_t_uint256_$_$_of_t_address(expr_109_slot,expr_110)
                let _23_slot := _22
                let expr_113_slot := _23_slot
                /// @src 0:1123:1133  "msg.sender"
                let expr_112 := caller()
                /// @src 0:1105:1134  "allowance[sender][msg.sender]"
                let _24 := mapping_index_access_t_mapping$_t_address_$_t_uint256_$_of_t_address(expr_113_slot,expr_112)
                /// @src 0:1105:1144  "allowance[sender][msg.sender] -= amount"
                let _25 := read_from_storage_split_offset_0_t_uint256(_24)
                let expr_116 := checked_sub_t_uint256(_25, expr_115)

                update_storage_value_offset_0t_uint256_to_t_uint256(_24, expr_116)
                /// @src 0:1175:1181  "amount"
                let _26 := var_amount_104
                let expr_121 := _26
                /// @src 0:1154:1163  "balanceOf"
                let _27_slot := 0x01
                let expr_118_slot := _27_slot
                /// @src 0:1164:1170  "sender"
                let _28 := var_sender_100
                let expr_119 := _28
                /// @src 0:1154:1171  "balanceOf[sender]"
                let _29 := mapping_index_access_t_mapping$_t_address_$_t_uint256_$_of_t_address(expr_118_slot,expr_119)
                /// @src 0:1154:1181  "balanceOf[sender] -= amount"
                let _30 := read_from_storage_split_offset_0_t_uint256(_29)
                let expr_122 := checked_sub_t_uint256(_30, expr_121)

                update_storage_value_offset_0t_uint256_to_t_uint256(_29, expr_122)
                /// @src 0:1215:1221  "amount"
                let _31 := var_amount_104
                let expr_127 := _31
                /// @src 0:1191:1200  "balanceOf"
                let _32_slot := 0x01
                let expr_124_slot := _32_slot
                /// @src 0:1201:1210  "recipient"
                let _33 := var_recipient_102
                let expr_125 := _33
                /// @src 0:1191:1211  "balanceOf[recipient]"
                let _34 := mapping_index_access_t_mapping$_t_address_$_t_uint256_$_of_t_address(expr_124_slot,expr_125)
                /// @src 0:1191:1221  "balanceOf[recipient] += amount"
                let _35 := read_from_storage_split_offset_0_t_uint256(_34)
                let expr_128 := checked_add_t_uint256(_35, expr_127)

                update_storage_value_offset_0t_uint256_to_t_uint256(_34, expr_128)
                /// @src 0:1245:1251  "sender"
                let _36 := var_sender_100
                let expr_131 := _36
                /// @src 0:1253:1262  "recipient"
                let _37 := var_recipient_102
                let expr_132 := _37
                /// @src 0:1264:1270  "amount"
                let _38 := var_amount_104
                let expr_133 := _38
                /// @src 0:1236:1271  "Transfer(sender, recipient, amount)"
                let _39 := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                let _40 := convert_t_address_to_t_address(expr_131)
                let _41 := convert_t_address_to_t_address(expr_132)
                {
                    let _42 := allocate_unbounded()
                    let _43 := abi_encode_tuple_t_uint256__to_t_uint256__fromStack(_42 , expr_133)
                    log3(_42, sub(_43, _42) , _39, _40, _41)
                }/// @src 0:1288:1292  "true"
                let expr_136 := 0x01
                /// @src 0:1281:1292  "return true"
                var__107 := expr_136
                leave

            }
            /// @src 0:58:1653  "contract ERC20 {..."

            function cleanup_t_rational_0_by_1(value) -> cleaned {
                cleaned := value
            }

            function convert_t_rational_0_by_1_to_t_uint160(value) -> converted {
                converted := cleanup_t_uint160(identity(cleanup_t_rational_0_by_1(value)))
            }

            function convert_t_rational_0_by_1_to_t_address(value) -> converted {
                converted := convert_t_rational_0_by_1_to_t_uint160(value)
            }

            /// @ast-id 193
            /// @src 0:1481:1651  "function burn(uint amount) external {..."
            function fun_burn_193(var_amount_168) {

                /// @src 0:1552:1558  "amount"
                let _44 := var_amount_168
                let expr_175 := _44
                /// @src 0:1527:1536  "balanceOf"
                let _45_slot := 0x01
                let expr_171_slot := _45_slot
                /// @src 0:1537:1547  "msg.sender"
                let expr_173 := caller()
                /// @src 0:1527:1548  "balanceOf[msg.sender]"
                let _46 := mapping_index_access_t_mapping$_t_address_$_t_uint256_$_of_t_address(expr_171_slot,expr_173)
                /// @src 0:1527:1558  "balanceOf[msg.sender] -= amount"
                let _47 := read_from_storage_split_offset_0_t_uint256(_46)
                let expr_176 := checked_sub_t_uint256(_47, expr_175)

                update_storage_value_offset_0t_uint256_to_t_uint256(_46, expr_176)
                /// @src 0:1583:1589  "amount"
                let _48 := var_amount_168
                let expr_179 := _48
                /// @src 0:1568:1589  "totalSupply -= amount"
                let _49 := read_from_storage_split_offset_0_t_uint256(0x00)
                let expr_180 := checked_sub_t_uint256(_49, expr_179)

                update_storage_value_offset_0t_uint256_to_t_uint256(0x00, expr_180)
                /// @src 0:1613:1623  "msg.sender"
                let expr_184 := caller()
                /// @src 0:1633:1634  "0"
                let expr_187 := 0x00
                /// @src 0:1625:1635  "address(0)"
                let expr_188 := convert_t_rational_0_by_1_to_t_address(expr_187)
                /// @src 0:1637:1643  "amount"
                let _50 := var_amount_168
                let expr_189 := _50
                /// @src 0:1604:1644  "Transfer(msg.sender, address(0), amount)"
                let _51 := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                let _52 := convert_t_address_to_t_address(expr_184)
                let _53 := convert_t_address_to_t_address(expr_188)
                {
                    let _54 := allocate_unbounded()
                    let _55 := abi_encode_tuple_t_uint256__to_t_uint256__fromStack(_54 , expr_189)
                    log3(_54, sub(_55, _54) , _51, _52, _53)
                }
            }
            /// @src 0:58:1653  "contract ERC20 {..."

            /// @ast-id 166
            /// @src 0:1305:1475  "function mint(uint amount) external {..."
            function fun_mint_166(var_amount_141) {

                /// @src 0:1376:1382  "amount"
                let _56 := var_amount_141
                let expr_148 := _56
                /// @src 0:1351:1360  "balanceOf"
                let _57_slot := 0x01
                let expr_144_slot := _57_slot
                /// @src 0:1361:1371  "msg.sender"
                let expr_146 := caller()
                /// @src 0:1351:1372  "balanceOf[msg.sender]"
                let _58 := mapping_index_access_t_mapping$_t_address_$_t_uint256_$_of_t_address(expr_144_slot,expr_146)
                /// @src 0:1351:1382  "balanceOf[msg.sender] += amount"
                let _59 := read_from_storage_split_offset_0_t_uint256(_58)
                let expr_149 := checked_add_t_uint256(_59, expr_148)

                update_storage_value_offset_0t_uint256_to_t_uint256(_58, expr_149)
                /// @src 0:1407:1413  "amount"
                let _60 := var_amount_141
                let expr_152 := _60
                /// @src 0:1392:1413  "totalSupply += amount"
                let _61 := read_from_storage_split_offset_0_t_uint256(0x00)
                let expr_153 := checked_add_t_uint256(_61, expr_152)

                update_storage_value_offset_0t_uint256_to_t_uint256(0x00, expr_153)
                /// @src 0:1445:1446  "0"
                let expr_158 := 0x00
                /// @src 0:1437:1447  "address(0)"
                let expr_159 := convert_t_rational_0_by_1_to_t_address(expr_158)
                /// @src 0:1449:1459  "msg.sender"
                let expr_161 := caller()
                /// @src 0:1461:1467  "amount"
                let _62 := var_amount_141
                let expr_162 := _62
                /// @src 0:1428:1468  "Transfer(address(0), msg.sender, amount)"
                let _63 := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                let _64 := convert_t_address_to_t_address(expr_159)
                let _65 := convert_t_address_to_t_address(expr_161)
                {
                    let _66 := allocate_unbounded()
                    let _67 := abi_encode_tuple_t_uint256__to_t_uint256__fromStack(_66 , expr_162)
                    log3(_66, sub(_67, _66) , _63, _64, _65)
                }
            }
            /// @src 0:58:1653  "contract ERC20 {..."

            /// @ast-id 70
            /// @src 0:522:759  "function transfer(address recipient, uint amount) external returns (bool) {..."
            function fun_transfer_70(var_recipient_40, var_amount_42) -> var__45 {
                /// @src 0:590:594  "bool"
                let zero_t_bool_68 := zero_value_for_split_t_bool()
                var__45 := zero_t_bool_68

                /// @src 0:631:637  "amount"
                let _69 := var_amount_42
                let expr_51 := _69
                /// @src 0:606:615  "balanceOf"
                let _70_slot := 0x01
                let expr_47_slot := _70_slot
                /// @src 0:616:626  "msg.sender"
                let expr_49 := caller()
                /// @src 0:606:627  "balanceOf[msg.sender]"
                let _71 := mapping_index_access_t_mapping$_t_address_$_t_uint256_$_of_t_address(expr_47_slot,expr_49)
                /// @src 0:606:637  "balanceOf[msg.sender] -= amount"
                let _72 := read_from_storage_split_offset_0_t_uint256(_71)
                let expr_52 := checked_sub_t_uint256(_72, expr_51)

                update_storage_value_offset_0t_uint256_to_t_uint256(_71, expr_52)
                /// @src 0:671:677  "amount"
                let _73 := var_amount_42
                let expr_57 := _73
                /// @src 0:647:656  "balanceOf"
                let _74_slot := 0x01
                let expr_54_slot := _74_slot
                /// @src 0:657:666  "recipient"
                let _75 := var_recipient_40
                let expr_55 := _75
                /// @src 0:647:667  "balanceOf[recipient]"
                let _76 := mapping_index_access_t_mapping$_t_address_$_t_uint256_$_of_t_address(expr_54_slot,expr_55)
                /// @src 0:647:677  "balanceOf[recipient] += amount"
                let _77 := read_from_storage_split_offset_0_t_uint256(_76)
                let expr_58 := checked_add_t_uint256(_77, expr_57)

                update_storage_value_offset_0t_uint256_to_t_uint256(_76, expr_58)
                /// @src 0:701:711  "msg.sender"
                let expr_62 := caller()
                /// @src 0:713:722  "recipient"
                let _78 := var_recipient_40
                let expr_63 := _78
                /// @src 0:724:730  "amount"
                let _79 := var_amount_42
                let expr_64 := _79
                /// @src 0:692:731  "Transfer(msg.sender, recipient, amount)"
                let _80 := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                let _81 := convert_t_address_to_t_address(expr_62)
                let _82 := convert_t_address_to_t_address(expr_63)
                {
                    let _83 := allocate_unbounded()
                    let _84 := abi_encode_tuple_t_uint256__to_t_uint256__fromStack(_83 , expr_64)
                    log3(_83, sub(_84, _83) , _80, _81, _82)
                }/// @src 0:748:752  "true"
                let expr_67 := 0x01
                /// @src 0:741:752  "return true"
                var__45 := expr_67
                leave

            }
            /// @src 0:58:1653  "contract ERC20 {..."

        }

        data ".metadata" hex"a26469706673582212208238a3eaf7857251b887ed80095d9791fb68929ed8094996647e63496b14031d64736f6c63430008180033"
    }

}