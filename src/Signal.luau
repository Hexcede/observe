local Types = require(script.Parent.Types)

type Cleanup = Types.Cleanup
type Handler<T> = Types.Handler<T>
type Callback<T> = Types.Callback<T>

type Signal<T...> = Types.Signal<T...>
type Connection = Types.Connection

local State = require(script.Parent.State)

local ObserveValue = State.Value
local ObserveDistinctArray = State.DistinctArray
local ObserveClearableValue = State.ClearableValue

--[=[
    Observe a signal and call a handler with whatever value the signal passes to it.
]=]
local function ObserveChangedSignal<T>(value: T, changed: Signal<T>, fn: Handler<T>): Cleanup
    local cleanup, onChanged = ObserveValue(value, fn)

    local connection = changed:Connect(onChanged)

    return function()
        connection:Disconnect()

        cleanup()
    end
end

--[=[
    Observe a set and clear signal and call a handler with whatever value the set signal passes to it.
    If the clear signal is fired, the handler will be called with nil.
]=]
local function ObserveSetClearSignals<T>(value: T, set: Signal<T>, clear: Signal<any>, fn: Handler<T?>): Cleanup
    local cleanup, onChanged = ObserveClearableValue(value, fn)

    local function onClear()
        onChanged(nil)
    end

    local setConnection = set:Connect(onChanged)
    local clearConnection = clear:Connect(onClear)

    return function()
        setConnection:Disconnect()
        clearConnection:Disconnect()

        cleanup()
    end
end

--[=[
    Observe an added and removed signal and call a handler any time a distinct value is added.
    The handler will be called with all distinct values that are added.
    When a value is removed, the associated cleanup will be called.
]=]
function ObserveAddedRemovedSignals<T>(values: {T}, added: Signal<T>, removed: Signal<T>, fn: Handler<T>): Cleanup
    local cleanup, onAdded, onRemoved = ObserveDistinctArray(values, fn)

    -- Connect the signals
    local addedConnection = added:Connect(onAdded)
    local removedConnection = removed:Connect(onRemoved)

    return function()
        addedConnection:Disconnect()
        removedConnection:Disconnect()

        cleanup()
    end
end

local Signal = {
    ChangedSignal = ObserveChangedSignal,
    SetClearSignals = ObserveSetClearSignals,
    AddedRemovedSignals = ObserveAddedRemovedSignals,
}

return Signal