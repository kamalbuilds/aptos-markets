"use client";

import { BRAND_CONFIG } from '@/lib/brand/config';
import { motion } from 'framer-motion';
import { Activity, Zap, Target } from 'lucide-react';

interface LogoProps {
  showText?: boolean;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export function Logo({ showText = true, size = 'md', className = '' }: LogoProps) {
  const sizeConfig = {
    sm: {
      icon: 'w-6 h-6',
      text: 'text-lg',
      container: 'gap-2'
    },
    md: {
      icon: 'w-8 h-8',
      text: 'text-xl',
      container: 'gap-3'
    },
    lg: {
      icon: 'w-12 h-12',
      text: 'text-3xl',
      container: 'gap-4'
    }
  };

  const config = sizeConfig[size];

  return (
    <motion.div
      className={`flex items-center ${config.container} ${className}`}
      whileHover={{ scale: 1.02 }}
      transition={{ type: "spring", stiffness: 300 }}
    >
      {/* Logo Icon */}
      <div className="relative">
        <motion.div
          className={`
            ${config.icon} rounded-xl flex items-center justify-center
            bg-gradient-to-br from-blue-500 via-blue-600 to-purple-600
            shadow-lg shadow-blue-500/25
          `}
          whileHover={{
            scale: 1.1,
            rotate: 5,
            boxShadow: "0 20px 40px rgba(59, 130, 246, 0.4)"
          }}
          transition={{ type: "spring", stiffness: 300 }}
        >
          {/* Animated Icon */}
          <motion.div
            animate={{
              rotateY: [0, 360],
            }}
            transition={{
              duration: 8,
              repeat: Infinity,
              ease: "linear"
            }}
          >
            <Target className={`${size === 'sm' ? 'w-4 h-4' : size === 'md' ? 'w-5 h-5' : 'w-7 h-7'} text-white`} />
          </motion.div>
        </motion.div>

        {/* Animated Pulse Ring */}
        <motion.div
          className="absolute inset-0 rounded-xl border-2 border-blue-400 opacity-0"
          animate={{
            scale: [1, 1.2, 1],
            opacity: [0, 0.8, 0]
          }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
      </div>

      {/* Brand Text */}
      {showText && (
        <motion.div
          className="flex flex-col"
          initial={{ opacity: 0, x: -10 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.1 }}
        >
          <div className={`
            font-bold ${config.text} 
            bg-gradient-to-r from-blue-600 via-purple-600 to-blue-800 
            bg-clip-text text-transparent
            leading-tight
          `}>
            {BRAND_CONFIG.name}
          </div>
          {size === 'lg' && (
            <motion.div
              className="text-sm text-gray-600 dark:text-gray-400 -mt-1"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.3 }}
            >
              {BRAND_CONFIG.tagline}
            </motion.div>
          )}
        </motion.div>
      )}
    </motion.div>
  );
}

// Minimal logo variant for compact spaces
export function LogoMini({ className = '' }: { className?: string }) {
  return (
    <motion.div
      className={`w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center shadow-lg ${className}`}
      whileHover={{ scale: 1.1, rotate: 5 }}
      whileTap={{ scale: 0.95 }}
    >
      <Target className="w-5 h-5 text-white" />
    </motion.div>
  );
}

// Animated logo for loading states
export function LogoSpinner({ size = 'md' }: { size?: 'sm' | 'md' | 'lg' }) {
  const sizeClass = size === 'sm' ? 'w-6 h-6' : size === 'md' ? 'w-8 h-8' : 'w-12 h-12';

  return (
    <motion.div
      className={`${sizeClass} rounded-xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center`}
      animate={{ rotate: 360 }}
      transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
    >
      <Activity className={`${size === 'sm' ? 'w-3 h-3' : size === 'md' ? 'w-4 h-4' : 'w-6 h-6'} text-white`} />
    </motion.div>
  );
}

// Logo with background for hero sections
export function LogoHero() {
  return (
    <div className="relative">
      {/* Background Glow */}
      <motion.div
        className="absolute inset-0 bg-gradient-to-r from-blue-600/20 via-purple-600/20 to-blue-600/20 rounded-2xl blur-xl"
        animate={{
          scale: [1, 1.1, 1],
          opacity: [0.5, 0.8, 0.5]
        }}
        transition={{
          duration: 3,
          repeat: Infinity,
          ease: "easeInOut"
        }}
      />

      {/* Main Logo */}
      <div className="relative bg-white dark:bg-slate-900 rounded-2xl p-6 shadow-2xl border border-gray-200 dark:border-gray-800">
        <Logo size="lg" />
      </div>

      {/* Floating Elements */}
      <motion.div
        className="absolute -top-2 -right-2 w-4 h-4 bg-blue-500 rounded-full"
        animate={{
          y: [0, -10, 0],
          opacity: [0.5, 1, 0.5]
        }}
        transition={{
          duration: 2,
          repeat: Infinity,
          ease: "easeInOut"
        }}
      />
      <motion.div
        className="absolute -bottom-2 -left-2 w-3 h-3 bg-purple-500 rounded-full"
        animate={{
          y: [0, 8, 0],
          opacity: [0.5, 1, 0.5]
        }}
        transition={{
          duration: 2.5,
          repeat: Infinity,
          ease: "easeInOut",
          delay: 0.5
        }}
      />
    </div>
  );
}
