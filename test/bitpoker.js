const BitPoker = artifacts.require("../contracts/BitPoker.sol");

contract('BitPoker', async(accounts) => {
    it("test deposit ok", async () => {
        let instance = await BitPoker.new({'from': accounts[0]});

        let v1 = 1130023456789012098, v2 = 1430023456789000000, userId = 92400;

        let r1 = await instance.sendTransaction({'value': v1, 'from': accounts[0]});
        assert.equal(r1.logs[0].args.src, accounts[0]);

        let r2 = await instance.confirmDeposit([accounts[0]], [userId], {'from': accounts[0]});
        assert.equal(r2.logs[0].args.userId, userId);

        let b1 = await instance.balanceOf.call(userId);
        assert.equal(b1.toNumber(), v1);

        await instance.sendTransaction({'value': v2, 'from': accounts[0]});
        await instance.confirmDeposit([accounts[0]], [userId], {'from': accounts[0]});

        let b2 = await instance.balanceOf.call(userId);
        assert.equal(b2.toNumber(), v1 + v2);
    });

    it("test withdraw ok", async () => {
        let instance = await BitPoker.new({'from': accounts[0]});

        let v = 1130023456789012098, userId = 123;

        await instance.sendTransaction({'value': v, 'from': accounts[0]});

        await instance.confirmDeposit([accounts[0]], [userId], {'from': accounts[0]});

        await instance.transferTo(userId, accounts[1], v, {'from': accounts[0]});

        try {
            await instance.transferTo(userId, accounts[1], 1, {'from': accounts[0]});
            assert.ok(false, "no result should be returned.");
        } catch (err) {
            assert.ok(true, "exception should be raised.");
        }
    });

    it("test close", async () => {
        let instance = await BitPoker.new({'from': accounts[0]});

        await instance.close(accounts[0], {'from': accounts[0]});

        try {
            await instance.sendTransaction({
                'value': 1130023456789012098,
                'from': accounts[0]
            });
            assert.ok(false, "no result should be returned.");
        } catch (err) {
            assert.ok(true, "exception should be raised.");
        }

        try {
            await instance.settle({'from': accounts[0]});
            assert.ok(false, "no result should be returned.");
        } catch (err) {
            assert.ok(true, "exception should be raised.");
        }
    });
});