import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

export const userPool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER_USER,
    password: process.env.DB_USER_PASSWORD,
    database: process.env.DB_NAME,  
});

export const adminPool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_ADMIN_USER,
    password: process.env.DB_ADMIN_PASSWORD,
    database: process.env.DB_NAME, 
});

console.log('DB_USER_USER =', process.env.DB_USER_USER);
console.log('DB_ADMIN_USER =', process.env.DB_ADMIN_USER);

// export default pool;