const BitPoker = artifacts.require("../contracts/BitPoker.sol");

contract('BitPoker', async(accounts) => {
    it("test deposit ok", async () => {
        let instance = await BitPoker.new({'from': accounts[0]});

        let v1 = 1130023456789012098, v2 = 1430023456789000000, userId = 92400;

        let r1 = await instance.sendTransaction({'value': v1, 'from': accounts[0]});
        assert.equal(r1.logs[0].args.src, accounts[0]);

        let r2 = await instance.confirmDeposit(userId, accounts[0], {'from': accounts[0]});
        assert.equal(r2.logs[0].args.userId, userId);

        let b1 = await instance.balanceOf.call(userId);
        assert.equal(b1.toNumber(), v1);

        await instance.sendTransaction({'value': v2, 'from': accounts[0]});
        await instance.confirmDeposit(userId, accounts[0], {'from': accounts[0]});

        let b2 = await instance.balanceOf.call(userId);
        assert.equal(b2.toNumber(), v1 + v2);
    });

    it("test withdraw ok", async () => {
        let instance = await BitPoker.new({'from': accounts[0]});

        let v = 1130023456789012098 * 2, userId = 123;
        let half = v / 2;

        await instance.sendTransaction({'value': v, 'from': accounts[0]});

        await instance.confirmDeposit(userId, accounts[0], {'from': accounts[0]});

        let r = await instance.withdrawTo(userId, accounts[1], half, {'from': accounts[0]});
        assert.equal(r.logs[0].args.userId, userId);
        assert.equal(r.logs[0].args.dst, accounts[1]);
        assert.equal(r.logs[0].args.amount, half);

        await instance.withdrawAllTo(userId, accounts[1], {'from': accounts[0]});

        try {
            await instance.withdrawTo(userId, accounts[1], 1, {'from': accounts[0]});
            assert.ok(false, "no result should be returned.");
        } catch (err) {
            assert.ok(true, "exception should be raised.");
        }
    });

    it("test deactivate and close", async () => {
        let instance = await BitPoker.new({'from': accounts[0]});

        await instance.deactivate({'from': accounts[0]});

        try {
            await instance.sendTransaction({
                'value': 1130023456789012098,
                'from': accounts[0]
            });
            assert.ok(false, "no result should be returned.");
        } catch (err) {
            assert.ok(true, "exception should be raised.");
        }

        await instance.close({'from': accounts[0]});

        try {
            await instance.sendTransaction({
                'value': 1130023456789012098,
                'from': accounts[0]
            });
            assert.ok(false, "no result should be returned.");
        } catch (err) {
            assert.ok(true, "exception should be raised.");
        }
    });
});