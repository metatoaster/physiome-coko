process.env.NODE_ENV = 'test';
process.env.BABEL_ENV = 'test';

const config = require('config');
const path = require('path');
const webpack = require('webpack');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const rules = require('./rules.production');
const resolve = require('./common-resolve');

module.exports = [
    {
        name: 'app',
        target: 'web',
        context: path.join(__dirname, '..', 'app'),
        entry: {
            app: ['./app'],
        },
        output: {
            path: path.join(__dirname, '..', '_build', 'assets'),
            filename: '[name].[hash].js',
            publicPath: '/assets/',
        },
        module: {
            rules,
        },
        resolve,
        devtool: 'eval',
        plugins: [
            new CleanWebpackPlugin(['assets'], {
                root: path.join(__dirname, '..', '_build'),
            }),
            new HtmlWebpackPlugin({
                title: 'Physiome Submission Portal',
                buildTime: new Date().toString(),
                template: '../app/index-production.html',
                inject: 'body',
            }),
            new webpack.DefinePlugin({
                'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
            }),
            new webpack.ContextReplacementPlugin(/./, __dirname, {
            }),
            new ExtractTextPlugin('styles/main.css'),
            new CopyWebpackPlugin([{ from: '../static' }]),
            new webpack.optimize.AggressiveMergingPlugin(),
            new webpack.optimize.OccurrenceOrderPlugin(),
            new UglifyJSPlugin({
                sourceMap: true,
            }),
        ],
        node: {
            fs: 'empty',
            __dirname: true,
        },
    }
];
