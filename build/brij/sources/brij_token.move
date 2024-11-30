module brij::brij_token{

use sui::url::{Self};
use sui::coin::{Self, TreasuryCap};

public struct BRIJ_TOKEN has drop {}

fun init(witness: BRIJ_TOKEN, ctx: &mut TxContext) {
		let (treasury, metadata) = coin::create_currency(
				witness,
				6,
				b"BRJ",
				b"Brij",
				b"Token for contribution",
				option::some(url::new_unsafe_from_bytes(b"https://gateway.pinata.cloud/ipfs/QmfUEmpRzeFUPFN6UcoZ1PawrbE7PY8KeGyFC2xnHzH1jE")),
				ctx,
		);
		transfer::public_freeze_object(metadata);
		transfer::public_share_object(treasury);
}

public fun mint(
		treasury_cap: &mut TreasuryCap<BRIJ_TOKEN>,
		amount: u64,
		recipient: address,
		ctx: &mut TxContext,
) {
		let coin = coin::mint(treasury_cap, amount, ctx);
		transfer::public_transfer(coin, recipient)
}


}