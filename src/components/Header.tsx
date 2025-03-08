import React from 'react';
import { User, Menu, Stethoscope } from 'lucide-react';
import ThemeToggle from './ThemeToggle';
import { Link } from 'react-router-dom';

interface Props {
  isMobile: boolean;
  onMenuClick: () => void;
}

const Header = ({ isMobile, onMenuClick }: Props) => {
  return (
    <header className="bg-white dark:bg-dark-lighter shadow transition-colors">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            {isMobile && (
              <>
                <button
                  onClick={onMenuClick}
                  className="p-2 rounded-lg text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 mr-4"
                >
                  <Menu className="w-6 h-6" />
                </button>
                <Link to="/" className="flex items-center gap-3">
                  <div className="bg-blue-600 p-2 rounded-lg">
                    <Stethoscope className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <h1 className="text-xl font-bold text-gray-900 dark:text-white">PREPCLEX</h1>
                    <p className="text-xs text-gray-500 dark:text-gray-400">NCLEX Prep</p>
                  </div>
                </Link>
              </>
            )}
          </div>
          <div className="flex items-center space-x-4">
            <ThemeToggle />
            <div className="flex items-center text-gray-600 dark:text-gray-300 hover:text-blue-600">
              <User className="w-5 h-5 mr-2" />
              <span className="text-sm">John McManaman</span>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;