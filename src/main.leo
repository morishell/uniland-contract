// The 'flipflap' program.
program mori.aleo {
    mapping is_voted: Voted => bool;
    mapping nodes: u128 => Node;
    mapping node_exist: u128 => bool;
    mapping node_votes: u128 => u32;

    record Vote {
        owner: address,
        gates: u64,
        sender: address,
        node_id: u128,
        mov: u8,
    }

    struct Voted {
        key1: field,
        key2: field,
    }

    struct Node {
        node_id: u128,
        state: u128,
        parent_id: u128, // if is root node, parent_id is 0
        node_type: u8, // 0 for leaf 1 for internal node
        game_status: i8, // 0 for not end 1 for win -1 for lose 2 for draw
        valid_cnt: u32,
    }

    inline get_contract_onwer () -> address {
        return aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px; // need to change to your own address
    }

    transition move_to_next (node_id: u128, next_node_id: u128, new_state: u128, new_valid_cnt: u32, game_status: i8) {
        // check if is owner
        assert_eq(self.caller, get_contract_onwer());
        return then finalize(node_id, next_node_id, new_state, new_valid_cnt, game_status);
    }

    finalize move_to_next (node_id: u128, next_node_id: u128, new_state: u128, new_valid_cnt: u32, game_status: i8) {
        // check if is exist
        let is_exist: bool = Mapping::get_or_init(node_exist, node_id, false);
        assert_eq(is_exist, true);

        let parent: Node = Mapping::get(nodes, node_id);

        // check if is enough votes to move
        let votes: u32 = Mapping::get_or_init(node_votes, node_id, 0u32);
        let valid_cnt: u32 = parent.valid_cnt / 2u32;
        let is_enough: bool = votes >= valid_cnt;
        assert(is_enough);

        // update old node
        let new_parent: Node = Node {
            node_id: parent.node_id,
            state: parent.state,
            parent_id: parent.parent_id,
            node_type: 1u8, // to internal node
            game_status: parent.game_status,
            valid_cnt: parent.valid_cnt,
        };
        Mapping::set(nodes, node_id, new_parent);

        // create new node
        let son: Node = Node {
            node_id: next_node_id,
            state: new_state,
            parent_id: node_id,
            node_type: 0u8, // to leaf node
            game_status: game_status,
            valid_cnt: new_valid_cnt,
        };
        Mapping::set(nodes, son.node_id, son);
        Mapping::set(node_exist, son.node_id, true);
    }

    transition open_game (start_id: u128) {
        // check if is owner
        assert_eq(self.caller, get_contract_onwer());
        return then finalize(start_id);
    }

    finalize open_game (start_id: u128) {
        // check if is exist
        let is_exist: bool = Mapping::get_or_init(node_exist, start_id, false);
        assert_eq(is_exist, false);

        let node: Node = Node {
            node_id: start_id,
            state: 7083711853891053158400u128,
            parent_id: 0u128,
            node_type: 0u8,
            game_status: 0i8,
            valid_cnt: 4u32,
        };

        Mapping::set(nodes, start_id, node);
        Mapping::set(node_exist, start_id, true);
    }

    // Client Operations
    transition vote (node_id: u128, mov: u8) -> Vote {
        let caller_vote: Vote = Vote {
            owner: get_contract_onwer(),
            gates: 0u64,
            sender: self.caller,
            node_id: node_id,
            mov: mov,
        };
        let voted_key1: field = BHP512::hash(self.caller);
        let voted_key2: field = BHP512::hash(node_id);

        let is_valid: bool = mov <= 63u8;
        assert(is_valid);

        return caller_vote then finalize(node_id, voted_key1, voted_key2);
    }

    finalize vote (node_id: u128, voted_key1: field, voted_key2: field) {
        // check if is exist
        let is_exist: bool = Mapping::get_or_init(node_exist, node_id, false);
        assert_eq(is_exist, true);

        // check if is voted
        let voted: Voted = Voted {
            key1: voted_key1,
            key2: voted_key2,
        };
        let is_vote: bool = Mapping::get_or_init(is_voted, voted, false);
        assert_eq(is_vote, false);

        // check is valid
        let node: Node = Mapping::get(nodes, node_id);
        assert(node.game_status == 0i8);
        assert(node.node_type == 0u8);


        Mapping::set(is_voted, voted, true);
        let votes: u32 = Mapping::get_or_init(node_votes, node_id, 0u32);
        Mapping::set(node_votes, node_id, votes + 1u32);
    }
}
