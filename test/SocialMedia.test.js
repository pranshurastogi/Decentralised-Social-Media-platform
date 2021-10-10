const { expect } = require("chai");
const { ethers } = require("hardhat");

let socialMedia;
let creator;

before(async function() {
    const contractFactory = await ethers.getContractFactory("SocialMedia");
    socialMedia = await contractFactory.deploy();
    await socialMedia.deployed();

    [creator] = await ethers.getSigners();
});

describe("Working with config values", function() {
    it("Check the initialized config values", async function() {
        await socialMedia.initialize();
        expect(await socialMedia.getDownVoteThreshold()).to.equal(5);
        expect(await socialMedia.getNumberOfExcuses()).to.equal(1);
        expect(await socialMedia.getSuspensionPeriod()).to.equal(7);
    });
});

describe("Working with Post", function() {
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