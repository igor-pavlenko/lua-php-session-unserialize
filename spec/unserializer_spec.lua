local unserializer = require 'unserializer'

describe("Unserializer", function()
    describe("unserialize()", function()
        it("can unserialize integer values", function()
            local serialized = "a:1:{s:5:\"k_int\";i:1;}"
            local expectedResult = {k_int = 1}
            local actualResult = unserializer.unserialize(serialized)
            assert.are.same(actualResult, expectedResult)
        end)

        it("can unserialize boolean values", function()
            local serialized = "a:2:{s:11:\"k_bool_true\";b:1;s:12:\"k_bool_false\";b:0;}"
            local expectedResult = {k_bool_true = true, k_bool_false = false}
            local actualResult = unserializer.unserialize(serialized)
            assert.are.same(actualResult, expectedResult)
        end)

        it("can unserialize null/nil values", function()
            local serialized = "a:1:{s:5:\"k_nil\";N;}"
            local expectedResult = {k_nil = nil}
            local actualResult = unserializer.unserialize(serialized)
            assert.are.same(actualResult, expectedResult)
        end)

        it("can unserialize string values", function()
            local serialized = "a:1:{s:8:\"k_string\";s:11:\"Test String\";}"
            local expectedResult = {k_string = "Test String"}
            local actualResult = unserializer.unserialize(serialized)
            assert.are.same(actualResult, expectedResult)
        end)

        it("can unserialize array values", function()
            local serialized = "a:1:{s:7:\"k_array\";a:2:{s:2:\"k1\";i:1;s:2:\"k2\";i:2;}}"
            local expectedResult = {k_array = {k1 = 1, k2 = 2}}
            local actualResult = unserializer.unserialize(serialized)
            assert.are.same(actualResult, expectedResult)
        end)

        it("can unserialize array of array values", function()
            local serialized = "a:1:{s:13:\"k_array_array\";a:1:{s:2:\"k1\";a:1:{s:2:\"k2\";a:1:{s:2:\"k3\";s:4:\"DONE\";}}}}"
            local expectedResult = {k_array_array = {k1 = {k2 = {k3 = "DONE"}}}}
            local actualResult = unserializer.unserialize(serialized)
            assert.are.same(actualResult, expectedResult)
        end)

        it("does not support objects", function()
            local serialized = "a:1:{s:7:\"k_class\";O:12:\"TEST_CLASS_A\":1:{s:4:\"prop\";s:10:\"prop_value\";}}"
            local expectedResult = {}
            local actualResult = nil
            --local actualResult = unserializer.unserialize(serialized)
            assert.are.same(actualResult, expectedResult)
        end)
    end)
end)