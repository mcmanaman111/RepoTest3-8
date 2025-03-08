import React from 'react';
import { Line, Doughnut, Bar } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  ArcElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js';
import { Brain, Target, Clock, Trophy, ArrowRight, Zap, BookOpen } from 'lucide-react';

// Register ChartJS components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  ArcElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

const Dashboard2 = () => {
  // Mock data
  const performanceData = {
    labels: ['Test 1', 'Test 2', 'Test 3', 'Test 4', 'Test 5', 'Test 6'],
    datasets: [{
      label: 'Score',
      data: [75, 82, 78, 85, 88, 92],
      borderColor: '#2563eb',
      backgroundColor: 'rgba(37, 99, 235, 0.1)',
      fill: true,
      tension: 0.4,
      pointRadius: 6,
      pointBackgroundColor: '#2563eb',
      pointBorderColor: '#fff',
      pointBorderWidth: 2
    }]
  };

  const qbankData = {
    labels: ['Completed', 'Remaining', 'Flagged'],
    datasets: [{
      data: [750, 425, 75],
      backgroundColor: [
        'rgba(37, 99, 235, 0.8)',
        'rgba(209, 213, 219, 0.8)',
        'rgba(59, 130, 246, 0.5)'
      ],
      borderWidth: 0
    }]
  };

  const strengthsData = {
    labels: ['Med-Surg', 'Pediatrics', 'OB', 'Mental Health', 'Fundamentals'],
    datasets: [{
      label: 'Performance by Category',
      data: [92, 85, 78, 88, 90],
      backgroundColor: 'rgba(37, 99, 235, 0.8)',
      borderRadius: 8
    }]
  };

  return (
    <div className="p-6 space-y-6 bg-gray-50 dark:bg-dark min-h-screen">
      {/* Hero Section */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-800 rounded-2xl p-8 text-white">
        <div className="flex justify-between items-start">
          <div>
            <h1 className="text-3xl font-bold mb-2">Welcome back, John! 👋</h1>
            <p className="text-blue-100 mb-6">Ready to continue your NCLEX preparation?</p>
            <button className="bg-white text-blue-600 px-6 py-3 rounded-lg font-semibold hover:bg-blue-50 transition-colors flex items-center">
              Start New Test
              <ArrowRight className="ml-2 w-5 h-5" />
            </button>
          </div>
          <div className="text-right">
            <div className="text-5xl font-bold">92%</div>
            <div className="text-blue-100">Latest Score</div>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white dark:bg-dark-lighter rounded-xl p-6 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-blue-100 dark:bg-blue-900/30 p-3 rounded-lg">
              <Brain className="w-6 h-6 text-blue-600 dark:text-blue-400" />
            </div>
            <span className="text-sm text-green-500">+12% ↑</span>
          </div>
          <h3 className="text-3xl font-bold text-gray-800 dark:text-white mb-1">1,250</h3>
          <p className="text-gray-500 dark:text-gray-400">Questions Completed</p>
        </div>

        <div className="bg-white dark:bg-dark-lighter rounded-xl p-6 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-green-100 dark:bg-green-900/30 p-3 rounded-lg">
              <Target className="w-6 h-6 text-green-600 dark:text-green-400" />
            </div>
            <span className="text-sm text-green-500">+5% ↑</span>
          </div>
          <h3 className="text-3xl font-bold text-gray-800 dark:text-white mb-1">85%</h3>
          <p className="text-gray-500 dark:text-gray-400">Average Score</p>
        </div>

        <div className="bg-white dark:bg-dark-lighter rounded-xl p-6 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-purple-100 dark:bg-purple-900/30 p-3 rounded-lg">
              <Clock className="w-6 h-6 text-purple-600 dark:text-purple-400" />
            </div>
            <span className="text-sm text-purple-500">45.2 hrs</span>
          </div>
          <h3 className="text-3xl font-bold text-gray-800 dark:text-white mb-1">28</h3>
          <p className="text-gray-500 dark:text-gray-400">Study Days</p>
        </div>

        <div className="bg-white dark:bg-dark-lighter rounded-xl p-6 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-orange-100 dark:bg-orange-900/30 p-3 rounded-lg">
              <Trophy className="w-6 h-6 text-orange-600 dark:text-orange-400" />
            </div>
            <span className="text-sm text-orange-500">Level 4</span>
          </div>
          <h3 className="text-3xl font-bold text-gray-800 dark:text-white mb-1">15</h3>
          <p className="text-gray-500 dark:text-gray-400">Tests Completed</p>
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Performance Trend */}
        <div className="lg:col-span-2 bg-white dark:bg-dark-lighter rounded-xl p-6 shadow-sm">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h2 className="text-xl font-bold text-gray-800 dark:text-white">Performance Trend</h2>
              <p className="text-gray-500 dark:text-gray-400">Your test scores over time</p>
            </div>
            <div className="flex items-center space-x-2">
              <span className="text-sm text-green-500">+8.2% ↑</span>
              <button className="text-blue-600 dark:text-blue-400 hover:text-blue-700">View All</button>
            </div>
          </div>
          <Line 
            data={performanceData}
            options={{
              scales: {
                y: {
                  beginAtZero: true,
                  max: 100,
                  grid: { display: false },
                  ticks: { callback: value => `${value}%` }
                },
                x: { grid: { display: false } }
              },
              plugins: {
                legend: { display: false },
                tooltip: {
                  backgroundColor: 'rgba(0, 0, 0, 0.8)',
                  padding: 12,
                  titleFont: { size: 14 },
                  bodyFont: { size: 13 },
                  displayColors: false
                }
              }
            }}
          />
        </div>

        {/* QBank Progress */}
        <div className="bg-white dark:bg-dark-lighter rounded-xl p-6 shadow-sm">
          <h2 className="text-xl font-bold text-gray-800 dark:text-white mb-6">QBank Progress</h2>
          <div className="relative">
            <Doughnut
              data={qbankData}
              options={{
                cutout: '75%',
                plugins: {
                  legend: { display: false }
                }
              }}
            />
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="text-center">
                <div className="text-3xl font-bold text-gray-800 dark:text-white">1,250</div>
                <div className="text-sm text-gray-500">Total Questions</div>
              </div>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-4 mt-6">
            <div className="text-center">
              <div className="text-lg font-bold text-gray-800 dark:text-white">750</div>
              <div className="text-xs text-gray-500">Completed</div>
            </div>
            <div className="text-center">
              <div className="text-lg font-bold text-gray-800 dark:text-white">425</div>
              <div className="text-xs text-gray-500">Remaining</div>
            </div>
            <div className="text-center">
              <div className="text-lg font-bold text-gray-800 dark:text-white">75</div>
              <div className="text-xs text-gray-500">Flagged</div>
            </div>
          </div>
        </div>

        {/* Strengths Analysis */}
        <div className="lg:col-span-2 bg-white dark:bg-dark-lighter rounded-xl p-6 shadow-sm">
          <h2 className="text-xl font-bold text-gray-800 dark:text-white mb-6">Performance by Category</h2>
          <Bar
            data={strengthsData}
            options={{
              indexAxis: 'y',
              scales: {
                x: {
                  beginAtZero: true,
                  max: 100,
                  grid: { display: false }
                },
                y: { grid: { display: false } }
              },
              plugins: {
                legend: { display: false }
              }
            }}
          />
        </div>

        {/* Quick Actions */}
        <div className="bg-white dark:bg-dark-lighter rounded-xl p-6 shadow-sm">
          <h2 className="text-xl font-bold text-gray-800 dark:text-white mb-6">Quick Actions</h2>
          <div className="space-y-4">
            <button className="w-full bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 p-4 rounded-lg flex items-center justify-between hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors">
              <div className="flex items-center">
                <Zap className="w-5 h-5 mr-3" />
                <span>Quick 15 Questions</span>
              </div>
              <ArrowRight className="w-5 h-5" />
            </button>
            <button className="w-full bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 p-4 rounded-lg flex items-center justify-between hover:bg-purple-100 dark:hover:bg-purple-900/30 transition-colors">
              <div className="flex items-center">
                <BookOpen className="w-5 h-5 mr-3" />
                <span>Review Mistakes</span>
              </div>
              <ArrowRight className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard2;