const { expect } = require("chai");
const { ethers } = require("hardhat");

let socialMedia;
let creator;
let testAddr;

before(async function() {
    const contractFactory = await ethers.getContractFactory("SocialMedia");
    socialMedia = await contractFactory.deploy();
    await socialMedia.deployed();

    [creator, testAddr] = await ethers.getSigners();
});

describe("Working with config values", function() {
    it("Check the initialized config values", async function() {
        await socialMedia.initialize();
        expect(await socialMedia.getDownVoteThreshold()).to.equal(5);
        expect(await socialMedia.getNumberOfExcuses()).to.equal(1);
        expect(await socialMedia.getSuspensionPeriod()).to.equal(7);
    });

    it("Set config values", async function() {
        await socialMedia.setDownVoteThreshold(3);
        expect(await socialMedia.getDownVoteThreshold()).to.equal(3);
        await socialMedia.setNumberOfExcuses(2);
        expect(await socialMedia.getNumberOfExcuses()).to.equal(2);
        await socialMedia.setSuspensionPeriod(14);
        expect(await socialMedia.getSuspensionPeriod()).to.equal(14);
    });
});

describe("Working with Post, positive cases", function() {
    it("Create a post", async function() {
        await socialMedia.createPost("test description", "https://jibrish.ipfs");
        expect(await socialMedia.getAllPosts()).to.have.lengthOf(1);        
    });

    it ("Get a post by id", async function() {
        const post = await socialMedia.getPostById(1);
        expect(post).to.have.property("content", "https://jibrish.ipfs");
    });

    it ("Get post by user address", async function() {
        const postArray = await socialMedia.getPostsByUser(creator.address);
        expect(postArray.map(e => e.description)).to.include("test description");
    });

    it ("Get all posts", async function() {
        expect(await socialMedia.getAllPosts()).to.have.lengthOf(1);
    });
});

describe("Working with Post, negative cases", function() {
    it("Create a post with no content url", async function() {
        await expect(socialMedia.createPost("test1 description", "")).to.be.revertedWith('Empty content uri');
    });

    it("Call postById with non existant post", async function() {
        expect(await socialMedia.getPostById(5)).to.have.property("content", "");
    });
    
    it ("Get post by non existant user address", async function() {
        const postArray = await socialMedia.getPostsByUser(testAddr.address);
        expect(postArray).to.deep.equal([]);
    });
});

describe("Working with voting", function() {
    it("Caste a up vote", async function() {
        await socialMedia.vote(1, true);
        const vote = await socialMedia.getVoteByPostId(1);
        expect(vote).to.have.property('upVote');
        expect(vote.upVote).to.equal(1);
    });

    it("Caste a down vote", async function() {
        await socialMedia.vote(1, false);
        const vote = await socialMedia.getVoteByPostId(1);
        expect(vote).to.have.property('downVote');
        expect(vote.downVote).to.equal(1);
    });

    it ("Check both up vote and own dvote increment", async function() {
        await socialMedia.vote(1, true);
        await socialMedia.vote(1, false);
        const vote = await socialMedia.getVoteByPostId(1);
        expect(vote).to.have.property('upVote');
        expect(vote.upVote).to.equal(2);
        expect(vote).to.have.property('downVote');
        expect(vote.downVote).to.equal(2);
    });
});

describe("Working with reporting post violation", function() {
    it("Check the post violation", async function() {
        await expect(socialMedia.reportPostViolation(10)).to.be.revertedWith("Check the post ID");
        // not enough down votes
        await expect(socialMedia.reportPostViolation(1)).to.be.revertedWith("Can not take down the post");
        // post with id 1 is downvoted twice, do it again to match the threshold
        await socialMedia.vote(1, false);
        await socialMedia.reportPostViolation(1);
        expect(await socialMedia.getPostById(1)).to.have.property('visible', false);
        const violation = await socialMedia.getPostViolation(1);
        expect(violation.postIds).to.be.an('array').with.lengthOf(1);
    });
});