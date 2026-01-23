'use client';

import { forwardRef } from 'react';
import { motion, HTMLMotionProps } from 'framer-motion';
import clsx from 'clsx';

type ButtonVariant = 'primary' | 'secondary' | 'ghost';
type ButtonSize = 'sm' | 'md' | 'lg';

interface ButtonProps extends Omit<HTMLMotionProps<'button'>, 'ref'> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  href?: string;
  external?: boolean;
  children: React.ReactNode;
}

const variantStyles: Record<ButtonVariant, string> = {
  primary: `
    bg-gradient-to-r from-neon-pink to-neon-purple
    text-white font-semibold
    shadow-lg shadow-neon-pink/25
    hover:shadow-xl hover:shadow-neon-pink/40
    hover:from-neon-pink/90 hover:to-neon-purple/90
  `,
  secondary: `
    bg-transparent
    border border-neon-cyan
    text-neon-cyan font-medium
    shadow-md shadow-neon-cyan/10
    hover:bg-neon-cyan/10
    hover:shadow-lg hover:shadow-neon-cyan/25
  `,
  ghost: `
    bg-transparent
    text-neon-cyan font-medium
    hover:text-neon-pink
    hover:bg-white/5
  `,
};

const sizeStyles: Record<ButtonSize, string> = {
  sm: 'px-4 py-2 text-sm rounded-md',
  md: 'px-6 py-3 text-base rounded-lg',
  lg: 'px-8 py-4 text-lg rounded-lg',
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'primary',
      size = 'md',
      href,
      external = false,
      className,
      children,
      ...props
    },
    ref
  ) => {
    const baseStyles = `
      inline-flex items-center justify-center
      transition-all duration-200 ease-out
      focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-neon-cyan focus-visible:ring-offset-2 focus-visible:ring-offset-void-black
      disabled:opacity-50 disabled:cursor-not-allowed
    `;

    const buttonContent = (
      <motion.button
        ref={ref}
        className={clsx(baseStyles, variantStyles[variant], sizeStyles[size], className)}
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        {...props}
      >
        {children}
      </motion.button>
    );

    if (href) {
      const linkProps = external
        ? { target: '_blank', rel: 'noopener noreferrer' }
        : {};

      return (
        <motion.a
          href={href}
          className={clsx(baseStyles, variantStyles[variant], sizeStyles[size], className)}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          {...linkProps}
        >
          {children}
        </motion.a>
      );
    }

    return buttonContent;
  }
);

Button.displayName = 'Button';
