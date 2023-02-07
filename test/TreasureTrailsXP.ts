import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { assert, expect } from 'chai';
import { ethers } from 'hardhat';
import { TreasureTrailsXP } from '../typechain-types';
import { ACTIVITY_TYPE } from './enums';

describe('TreasureTrailsXP', function () {
  async function deployTreasure() {
    const [owner, otherAccount] = await ethers.getSigners();

    const TreasureTrailsXP = await ethers.getContractFactory(
      'TreasureTrailsXP',
      {
        libraries: {
          Utils: process.env.UTILS_ADDRESS || '',
        },
      }
    );
    const treasureTrailsXP = await TreasureTrailsXP.deploy('Disney', 3);

    return { treasureTrailsXP, owner, otherAccount };
  }

  describe('Initial State', function () {
    it('Add a Ticket', async function () {
      const { treasureTrailsXP } = await loadFixture(deployTreasure);

      const name = 'General2 Ticket';

      await treasureTrailsXP.addTicket(
        name,
        ethers.utils.parseEther('0.01'),
        1,
        50
      );
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
        ACTIVITY_TYPE.CHALLENGE
      );
      await treasureTrailsXP.toggleActivity(0, true);

      const challenges = await treasureTrailsXP.getActiveActivities(
        ACTIVITY_TYPE.CHALLENGE
      );

      assert.equal(challenges.length, 1);
    });

    it('Add an Attraction', async function () {
      const { treasureTrailsXP } = await loadFixture(deployTreasure);

      // Crear Atracción
      const name = 'SuperLoop2';
      const description = 'Superloca montañarusa';
      let date = new Date();
      date.setHours(date.getMinutes() + 5);

      await treasureTrailsXP.addActivity(
        name,
        description,
        0,
        10,
        date.getTime(),
        ACTIVITY_TYPE.ATTRACTION
      );
      await treasureTrailsXP.toggleActivity(0, true);
      const attractions = await treasureTrailsXP.getActiveActivities(
        ACTIVITY_TYPE.ATTRACTION
      );

      await expect(
        treasureTrailsXP.addActivity(
          name,
          description,
          0,
          10,
          date.getTime(),
          ACTIVITY_TYPE.ATTRACTION
        )
      ).to.be.reverted;

      assert.equal(attractions.length, 1);
    });
  });

  describe('General Data', function () {
    it('Get Tickets', async function () {
      const { treasureTrailsXP } = await loadFixture(deployTreasure);

      const name = 'General Ticket';
      const durationInDays = 1;

      await treasureTrailsXP.addTicket(
        name,
        ethers.utils.parseEther('0.01'),
        durationInDays,
        50
      );
      await treasureTrailsXP.addTicket(
        `${name} - 2`,
        ethers.utils.parseEther('0.015'),
        durationInDays,
        70
      );

      const tickets = await treasureTrailsXP.getTickets();

      assert.equal(tickets.length, 2);
    });
    it('Buy a Tickets', async function () {
      const { treasureTrailsXP, otherAccount } = await loadFixture(
        deployTreasure
      );

      const name = 'General Ticket';
      const durationInDays = 1;

      await treasureTrailsXP.addTicket(
        name,
        ethers.utils.parseEther('0.01'),
        durationInDays,
        50
      );
      await treasureTrailsXP.addTicket(
        `${name} - 2`,
        ethers.utils.parseEther('0.015'),
        durationInDays,
        70
      );

      await treasureTrailsXP
        .connect(otherAccount)
        .buyTicket(0, { value: ethers.utils.parseEther('0.01') });

      await expect(
        treasureTrailsXP
          .connect(otherAccount)
          .buyTicket(0, { value: ethers.utils.parseEther('0.01') })
      ).to.be.reverted;

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
      const durationInDays = 1;

      await treasureTrailsXP.addTicket(
        name,
        ethers.utils.parseEther('0.01'),
        durationInDays,
        50
      );

      // Crear Challenge
      name = 'Foto con Pluto';
      let description = 'Escanea el QR que plto tiene y gana 20 puntos';
      let date = new Date();
      date.setHours(date.getMinutes() + 5);

      await treasureTrailsXP.addActivity(
        name,
        description,
        30,
        0,
        date.getTime(),
        ACTIVITY_TYPE.CHALLENGE
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
        ACTIVITY_TYPE.ATTRACTION
      );
      await treasureTrailsXP.toggleActivity(1, true);

      ticket = await treasureTrailsXP.connect(otherAccount).getTicket(0);
      await treasureTrailsXP
        .connect(otherAccount)
        .buyTicket(0, { value: ethers.utils.parseEther('0.01') });
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

  describe('Restaurant', function () {
    it('Add a Restaurant', async function () {
      const { treasureTrailsXP } = await loadFixture(deployTreasure);

      const name = 'Lomiton';

      await treasureTrailsXP.addRestaurant(name);

      const restaurants = await treasureTrailsXP.getRestaurants();

      assert.equal(restaurants.length, 1);
    });

    it('Add a Meal', async function () {
      const { treasureTrailsXP } = await loadFixture(deployTreasure);

      // Crear Comida
      let name = 'Hamburguesa Brasileña';
      let description = 'Carne-Palta-Queso';

      await treasureTrailsXP.addActivity(
        name,
        description,
        0,
        20,
        0,
        ACTIVITY_TYPE.MEAL
      );

      await treasureTrailsXP.toggleActivity(0, true);

      const activities = await treasureTrailsXP.getActiveActivities(
        ACTIVITY_TYPE.MEAL
      );

      assert.equal(activities.length, 1);
    });
  });

  describe('Restaurante', function () {
    let treasureTrailsXP: TreasureTrailsXP;
    let otherAccount: any;
    let ticket: any;

    beforeEach(async () => {
      const salida = await loadFixture(deployTreasure);
      treasureTrailsXP = salida.treasureTrailsXP;
      otherAccount = salida.otherAccount;

      await treasureTrailsXP.addRestaurant('Lomiton');

      await treasureTrailsXP.addTicket(
        'General',
        ethers.utils.parseEther('0.01'),
        1,
        50
      );

      // Create Meal
      let name = 'Completo Italiano';
      let description = 'Tomate-Palta-Mayo';

      await treasureTrailsXP.addActivity(
        name,
        description,
        0,
        20,
        0,
        ACTIVITY_TYPE.MEAL
      );
      await treasureTrailsXP.toggleActivity(0, true);

      name = 'Churrasco Brasileño';
      description = 'Carne-Palta-Queso';

      await treasureTrailsXP.addActivity(
        name,
        description,
        0,
        15,
        0,
        ACTIVITY_TYPE.MEAL
      );
      await treasureTrailsXP.toggleActivity(1, true);

      name = 'Churrasco Italiano';
      description = 'Carne-Palta-Tomate';

      await treasureTrailsXP.addActivity(
        name,
        description,
        0,
        15,
        0,
        ACTIVITY_TYPE.MEAL
      );
      await treasureTrailsXP.toggleActivity(2, true);

      name = 'Ass Italiano';
      description = 'Carne-Palta-Tomate';

      await treasureTrailsXP.addActivity(
        name,
        description,
        0,
        15,
        0,
        ACTIVITY_TYPE.MEAL
      );
      await treasureTrailsXP.toggleActivity(3, true);

      await treasureTrailsXP
        .connect(otherAccount)
        .buyTicket(0, { value: ethers.utils.parseEther('0.01') });
    });

    it('Create Menu', async function () {
      const activities = await treasureTrailsXP.getActivities();

      const menu = new Array();

      activities.forEach((m, i) => {
        if (m.activityType === ACTIVITY_TYPE.MEAL && m.isActive && i % 2 === 0)
          menu.push(i);
      });

      await treasureTrailsXP.setMenuRestaurant(0, menu);

      const menuRestaurant = await treasureTrailsXP.getMenuRestaurant(0);
      const idsMenuRestaurant = await treasureTrailsXP.getIdsMenuRestaurant(0);

      assert.equal(menuRestaurant.length, idsMenuRestaurant.length);
    });

    it('Order a Meal', async function () {
      const activities = await treasureTrailsXP.getActivities();

      const menu = new Array();

      activities.forEach((m, i) => {
        if (m.activityType === ACTIVITY_TYPE.MEAL && m.isActive) menu.push(i);
      });

      await treasureTrailsXP.setMenuRestaurant(0, menu);

      let creditsBefore = await treasureTrailsXP
        .connect(otherAccount)
        .getCredits();

      const mealsToBuy = [0, 2];

      let mealCredits = ethers.BigNumber.from(0);
      mealsToBuy.forEach((m) => {
        mealCredits = mealCredits.add(activities[m].discountCredits);
      });

      await treasureTrailsXP.connect(otherAccount).buyMeals(0, mealsToBuy);

      let creditsAfter = await treasureTrailsXP
        .connect(otherAccount)
        .getCredits();

      assert.equal(
        creditsBefore.sub(mealCredits).toString(),
        creditsAfter.toString()
      );
    });
  });

  describe('Store', function () {
    let treasureTrailsXP: TreasureTrailsXP;
    let otherAccount: any;
    let ticket: any;

    beforeEach(async () => {
      const salida = await loadFixture(deployTreasure);
      treasureTrailsXP = salida.treasureTrailsXP;
      otherAccount = salida.otherAccount;

      await treasureTrailsXP.addStore('Oakley');

      await treasureTrailsXP.addTicket(
        'General',
        ethers.utils.parseEther('0.01'),
        1,
        50
      );

      // Create Meal
      let name = 'Lentes Bacanes';
      let description = 'de colores';

      await treasureTrailsXP.addActivity(
        name,
        description,
        0,
        20,
        0,
        ACTIVITY_TYPE.PRODUCT
      );
      await treasureTrailsXP.toggleActivity(0, true);

      name = 'Gorro de los Jets';
      description = 'Verde con Blanco';

      await treasureTrailsXP.addActivity(
        name,
        description,
        0,
        15,
        0,
        ACTIVITY_TYPE.PRODUCT
      );
      await treasureTrailsXP.toggleActivity(1, true);

      name = 'Guante de Baseball';
      description = 'de los Mets';

      await treasureTrailsXP.addActivity(
        name,
        description,
        0,
        15,
        0,
        ACTIVITY_TYPE.PRODUCT
      );
      await treasureTrailsXP.toggleActivity(2, true);

      name = 'Zapatillas tillas';
      description = 'coolisimas';

      await treasureTrailsXP.addActivity(
        name,
        description,
        0,
        15,
        0,
        ACTIVITY_TYPE.PRODUCT
      );
      await treasureTrailsXP.toggleActivity(3, true);

      await treasureTrailsXP
        .connect(otherAccount)
        .buyTicket(0, { value: ethers.utils.parseEther('0.01') });
    });

    it('Create store setup', async function () {
      const activities = await treasureTrailsXP.getActivities();

      const products = new Array();

      activities.forEach((m, i) => {
        if (
          m.activityType === ACTIVITY_TYPE.PRODUCT &&
          m.isActive &&
          i % 2 === 0
        )
          products.push(i);
      });

      await treasureTrailsXP.setProductsStore(0, products);

      const productsStore = await treasureTrailsXP.getProductsStore(0);
      const idsProductsStore = await treasureTrailsXP.getIdsProductsStore(0);

      assert.equal(productsStore.length, idsProductsStore.length);
    });

    it('Order my gifts', async function () {
      const activities = await treasureTrailsXP.getActivities();

      const products = new Array();

      activities.forEach((m, i) => {
        if (m.activityType === ACTIVITY_TYPE.PRODUCT && m.isActive)
          products.push(i);
      });

      await treasureTrailsXP.setProductsStore(0, products);

      let creditsBefore = await treasureTrailsXP
        .connect(otherAccount)
        .getCredits();

      const productsToBuy = [0, 2];

      let productsCredits = ethers.BigNumber.from(0);
      productsToBuy.forEach((m) => {
        productsCredits = productsCredits.add(activities[m].discountCredits);
      });

      await treasureTrailsXP
        .connect(otherAccount)
        .buyProducts(0, productsToBuy);

      let creditsAfter = await treasureTrailsXP
        .connect(otherAccount)
        .getCredits();

      assert.equal(
        creditsBefore.sub(productsCredits).toString(),
        creditsAfter.toString()
      );
    });
  });
});
