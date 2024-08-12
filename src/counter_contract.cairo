#[starknet::interface]
pub trait ICounter<TContractState> {
    fn increase_counter(ref self: TContractState);
    fn decrease_counter(ref self: TContractState, value: u32);
    fn get_counter(self: @TContractState) -> u32;
}

#[starknet::contract]
pub mod counter_contract {
    use starknet::ContractAddress;
    use openzeppelin::access::ownable::OwnableComponent;
    use kill_switch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait};
   
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

     #[abi(embed_v0)]
     impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
     impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
 

    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased,
        OwnableEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, value: u32, kill_switch: ContractAddress, initial_owner: ContractAddress) {
        self.counter.write(value);
        self.kill_switch.write(kill_switch);
        self.ownable.initializer(initial_owner);
    }

 

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        #[key]
        counter: u32
    }

    #[abi(embed_v0)]
    impl Counter of super::ICounter<ContractState> {
        fn increase_counter(ref self: ContractState) {
            self.ownable.assert_only_owner();
            let _is_active: bool = IKillSwitchDispatcher {
                contract_address: self.kill_switch.read()
            }
                .is_active();
            assert!(_is_active == false, "Kill Switch is active");
            let read_value: u32 = self.counter.read();
            self.counter.write(read_value + 1_u32);
            self.emit(Event::CounterIncreased(CounterIncreased { counter: self.counter.read() }));
        }

        fn decrease_counter(ref self: ContractState, value: u32) {
            let read_value: u32 = self.counter.read();
            self.counter.write(read_value - value);
        }

        fn get_counter(self: @ContractState) -> u32 {
            let read_value: u32 = self.counter.read();
            read_value
        }
    }
}
