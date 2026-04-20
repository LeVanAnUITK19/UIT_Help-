import mongoose from 'mongoose';
import dotenv from 'dotenv';
dotenv.config();

export const connectDB = async () => {
    try {
        const uri = process.env.MONGODB_CONNECTIONSTRING;
        if (!uri) {
            throw new Error('MONGODB_CONNECTIONSTRING chưa được định nghĩa');
        }
        await mongoose.connect(uri);
        console.log('Kết nối đến MongoDB thành công');
    } catch (error) {
        console.error('Lỗi kết nối đến MongoDB:', error);
        process.exit(1);
    }
};