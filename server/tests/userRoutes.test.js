const dotenv = require('dotenv');
dotenv.config();

// Mock the database connection
jest.mock('../src/config/db', () => jest.fn());

const request = require('supertest');
const app = require('../src/index');
const mongoose = require('mongoose');

// Mock mongoose connect to avoid actual DB connection during test or use a test DB
// For valid integration test we often want a real DB (e.g. in memory mongo)
// For simplicity here, I will just test the / endpoint or mock the model.
// But since I have actual DB connection in index.js, it might try to connect.
// I'll assume for this environment we rely on the actual DB or connection failure handled.

describe('User API', () => {
    it('GET / should return server status', async () => {
        const res = await request(app).get('/');
        expect(res.statusCode).toEqual(200);
        expect(res.text).toBe('Talkio Server is running');
    });

    // More complex tests would require mocking DB or running a test instance
});

afterAll(async () => {
    await mongoose.connection.close();
});
