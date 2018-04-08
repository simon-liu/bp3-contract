const BitPoker = artifacts.require("../contracts/BitPoker.sol");

contract('BitPoker', async(accounts) => {
    it("test deposit ok", async () => {
        let instance = await BitPoker.new();

        let v1 = 1130023456789012098, v2 = 1430023456789000000, userId = 92400;

        await instance.sendTransaction({'value': v1, 'data': '092400'});

        let b1 = await instance.balanceOf.call(userId);
        assert.equal(b1.toNumber(), v1);

        let result = await instance.sendTransaction({'value': v2, 'data': '092400'});

        assert.equal(result.logs[0].args.userId.toNumber(), userId);
        assert.equal(result.logs[0].args.amount.toNumber(), v2);

        assert.ok(result.logs[0].args.balance, v1 + v2);

        let b2 = await instance.balanceOf.call(userId);
        assert.equal(b2, v1 + v2);
    });

    it("test withdraw ok", async () => {
        let instance = await BitPoker.new({'from': accounts[0]});

        let v = 1130023456789012098;

        await instance.sendTransaction({'value': v, 'data': '123'});

        await instance.transferTo(123, accounts[1], v, {'from': accounts[0]});

        try {
            await instance.transferTo(123, accounts[1], 1, {'from': accounts[0]});
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
                'data': '092400',
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