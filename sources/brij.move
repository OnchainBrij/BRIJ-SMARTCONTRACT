module brij::brij{
    use std::string::String;
    use sui::clock::{Clock};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use brij::brij_token::{mint, BRIJ_TOKEN};



    const INVALID: u64 = 0;

    public struct Contributor has store, drop, copy {
        wallet_address: address,
        amount: u64,
        timestamp: u64,
    }

    public struct ProjectManager has key {
        id: UID,
        projects: vector<address>
    }

    public struct Project has key {
        id:UID,
        name: String,
        description: String,
        image: String,
        category: String,
        creator: address,
        target_amount: u64,
        current_amount: u64,
        deadline: u64,
        contributors: vector<Contributor>,
        funds: Balance<SUI>,
        is_active: bool,
        is_successful: bool
    }

    fun init(ctx: &mut TxContext) {
        let manager = ProjectManager {
            id: object::new(ctx),
            projects: vector::empty<address>(),
        };
        transfer::share_object(manager);
    }

    public fun create_project(manager: &mut ProjectManager, name: String, description: String, image: String, category: String, target_amount: u64, deadline: u64, ctx: &mut TxContext){
        let sender = tx_context::sender(ctx);

        let project = Project{
            id: object::new(ctx),
            name,
            description,
            image,
            category,
            creator: sender,
            target_amount,
            current_amount: 0,
            deadline,
            contributors: vector::empty<Contributor>(),
            funds: balance::zero(),
            is_active: true,
            is_successful: false
        };

        let project_id = object::id_address(&project);
        vector::push_back(&mut manager.projects, project_id);

        transfer::share_object(project);


    }

    public fun contribute(project: &mut Project,   payment: Coin<SUI>,
        clock: &Clock, treasury_cap: &mut TreasuryCap<BRIJ_TOKEN>,
        ctx: &mut TxContext ){
        
        let sender = tx_context::sender(ctx);
        let amount = coin::value(&payment);
        
        assert!(project.is_active, INVALID);
        let contributor = Contributor {
            wallet_address: sender,
            amount,
            timestamp: clock.timestamp_ms()
        };

        vector::push_back(&mut project.contributors, contributor);

        mint(treasury_cap, amount/100, sender, ctx);

        let payment_balance = coin::into_balance(payment);
        project.current_amount = project.current_amount + amount;
        balance::join(&mut project.funds, payment_balance);
        }


         public fun withdraw (project: &mut Project, clock: &Clock, ctx: &mut TxContext) {
        assert!(clock.timestamp_ms() > project.deadline, INVALID);
        assert!(project.is_active, INVALID);

        project.is_active = false;

        let available_funds = balance::value(&project.funds);

        if (available_funds > 0 ) {
            let withdraw_coin = coin::from_balance(balance::split(&mut project.funds, available_funds), ctx);

            transfer::public_transfer(withdraw_coin, project.creator)
        }

    }

        public fun finalize_project_campaign(
        project: &mut Project,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(clock.timestamp_ms() > project.deadline, INVALID);
        assert!(project.is_active, INVALID);

        project.is_active = false;
        project.is_successful = project.current_amount >= project.target_amount;

        if (project.is_successful) {
            // If successful, transfer funds to creator
            let funds_to_transfer = balance::value(&project.funds);
            let creator_coin = coin::from_balance(balance::split(&mut project.funds, funds_to_transfer), ctx);
            transfer::public_transfer(creator_coin, project.creator);
        }
    }


      public fun get_project_info(project: &Project): (
        String,    // name
        String,    // description
        String,  //Image
        String, //Category
        address,   // creator
        u64,      // target amount
        u64,      // current amount
        u64,      // deadline
        bool,     // is active
        bool      // is successful
    ) {
        (
            project.name,
            project.description,
            project.image,
            project.category,
            project.creator,
            project.target_amount,
            project.current_amount,
            project.deadline,
            project.is_active,
            project.is_successful
        )
    }

     public fun get_contributors(project: &Project): vector<Contributor> {
        project.contributors
    }

    public fun get_all_project(manager: &ProjectManager): vector<address> {
        manager.projects
    }

    public fun is_contributor(project: &Project, addr: address): (bool, u64) {
        let mut i = 0;
        let len = vector::length(&project.contributors);
        
        while (i < len) {
            let contributor = vector::borrow(&project.contributors, i);
            if (contributor.wallet_address == addr) {
                return (true, contributor.amount)
            };
            i = i + 1;
        };
        (false, 0)
    }



}