import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { assert } from 'chai';
import { ethers } from 'hardhat';
import { TreasureTrailsXP } from '../typechain-types';

describe('TreasureTrailsXP', function () {
  async function deployTreasure() {
    const [owner, otherAccount] = await ethers.getSigners();

    const TreasureTrailsXP = await ethers.getContractFactory(
      'TreasureTrailsXP'
    );
    const treasureTrailsXP = await TreasureTrailsXP.deploy();

    return { treasureTrailsXP, owner, otherAccount };
  }

  describe('Initial State', function () {
    it('Add a Ticket', async function () {
      const { treasureTrailsXP } = await loadFixture(deployTreasure);

      const name = 'General Ticket';
      const date = new Date();
      date.setHours(date.getHours() + 4);

      await treasureTrailsXP.addTicket(name, 150, date.getTime(), 50);
      const ticket = await treasureTrailsXP.getTicket(0);

      assert.equal(name, ticket.name);
    });

    it('Add a Challenge', async function () {
      const { treasureTrailsXP } = await loadFixture(deployTreasure);

      const name = 'Foto con Pluto';
      const description = 'Escanea el QR que plto tiene y gana 20 puntos';
      const date = new Date();
      date.setHours(date.getMinutes() + 5);

      await treasureTrailsXP.addActivity(
        name,
        description,
        30,
        0,
        date.getTime(),
        0
      );
      await treasureTrailsXP.toggleActivity(0, true);

      const challenges = await treasureTrailsXP.getActiveChallenges();

      assert.equal(challenges.length, 1);
    });
  });

  describe('General Data', function () {
    it('Get Tickets', async function () {
      const { treasureTrailsXP } = await loadFixture(deployTreasure);

      const name = 'General Ticket';
      const date = new Date();
      date.setHours(date.getHours() + 4);

      await treasureTrailsXP.addTicket(name, 150, date.getTime(), 50);
      await treasureTrailsXP.addTicket(`${name} - 2`, 150, date.getTime(), 50);
      const tickets = await treasureTrailsXP.getTickets();

      assert.equal(tickets.length, 2);
    });
    it('Buy a Tickets', async function () {
      const { treasureTrailsXP, otherAccount } = await loadFixture(
        deployTreasure
      );

      const name = 'General Ticket';
      const date = new Date();
      date.setHours(date.getHours() + 4);

      await treasureTrailsXP.addTicket(name, 150, date.getTime(), 50);
      await treasureTrailsXP.addTicket(`${name} - 2`, 150, date.getTime(), 50);

      await treasureTrailsXP.connect(otherAccount).buyTicket(0, { value: 150 });
      const myTickets = await treasureTrailsXP
        .connect(otherAccount)
        .getMyTickets();

      assert.equal(myTickets.length, 1);
    });
  });

  describe('Testing Player', function () {
    let treasureTrailsXP: TreasureTrailsXP;
    let otherAccount: any;
    let ticket: any;

    beforeEach(async () => {
      const salida = await loadFixture(deployTreasure);
      treasureTrailsXP = salida.treasureTrailsXP;
      otherAccount = salida.otherAccount;

      // Crear Ticket
      let name = 'General Ticket';
      let date = new Date();
      date.setHours(date.getHours() + 4);

      await treasureTrailsXP.addTicket(name, 150, date.getTime(), 50);

      // Crear Challenge
      name = 'Foto con Pluto';
      let description = 'Escanea el QR que plto tiene y gana 20 puntos';
      date = new Date();
      date.setHours(date.getMinutes() + 5);

      await treasureTrailsXP.addActivity(
        name,
        description,
        30,
        0,
        date.getTime(),
        0
      );
      await treasureTrailsXP.toggleActivity(0, true);

      // Crear Atracción
      name = 'SuperLoop';
      description = 'Superloca montañarusa';
      date = new Date();
      date.setHours(date.getMinutes() + 5);

      await treasureTrailsXP.addActivity(
        name,
        description,
        0,
        10,
        date.getTime(),
        2
      );
      await treasureTrailsXP.toggleActivity(0, true);

      ticket = await treasureTrailsXP.connect(otherAccount).getTicket(0);
      await treasureTrailsXP.connect(otherAccount).buyTicket(0, { value: 150 });
    });

    it('Win a Challenge', async function () {
      let credits = await treasureTrailsXP.connect(otherAccount).getCredits();

      const activity = await treasureTrailsXP.getActivity(0);
      await treasureTrailsXP.connect(otherAccount).completeChallenge(0);
      credits = await treasureTrailsXP.connect(otherAccount).getCredits();

      assert.equal(
        `${credits}`,
        ticket.initialCredits.add(activity.earnCredits).toString()
      );
    });

    it('In/out to an attraction', async function () {
      let attractionIndex = 1;
      let creditsBefore = await treasureTrailsXP
        .connect(otherAccount)
        .getCredits();

      let counterEntranceActivityBefore = await treasureTrailsXP
        .connect(otherAccount)
        .getEntranceCount(attractionIndex);

      await treasureTrailsXP
        .connect(otherAccount)
        .entranceAttraction(attractionIndex);

      let counterEntranceActivityAfter = await treasureTrailsXP
        .connect(otherAccount)
        .getEntranceCount(attractionIndex);

      assert(
        counterEntranceActivityBefore.toString(),
        counterEntranceActivityAfter.sub(1).toString()
      );

      const activity = await treasureTrailsXP.getActivity(attractionIndex);
      let creditsAfter = await treasureTrailsXP
        .connect(otherAccount)
        .getCredits();

      assert.equal(
        `${creditsAfter}`,
        creditsBefore.sub(activity.discountCredits).toString()
      );

      let counterExitActivityBefore = await treasureTrailsXP
        .connect(otherAccount)
        .getExitCount(attractionIndex);

      await treasureTrailsXP
        .connect(otherAccount)
        .exitAttraction(attractionIndex);

      let counterExitActivityAfter = await treasureTrailsXP
        .connect(otherAccount)
        .getExitCount(attractionIndex);

      assert(
        counterExitActivityBefore.toString(),
        counterExitActivityAfter.sub(1).toString()
      );

      let creditsAfterExit = await treasureTrailsXP
        .connect(otherAccount)
        .getCredits();

      assert.equal(
        `${creditsAfterExit}`,
        creditsAfter.add(activity.earnCredits).toString()
      );
    });
  });
});
