'use client';

import { forwardRef } from 'react';
import { motion, HTMLMotionProps } from 'framer-motion';
import clsx from 'clsx';

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'minimal' | 'outline' | 'soft';
type ButtonSize = 'sm' | 'md' | 'lg';

interface ButtonProps extends Omit<HTMLMotionProps<'button'>, 'ref'> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  href?: string;
  external?: boolean;
  children: React.ReactNode;
}

const variantStyles: Record<ButtonVariant, string> = {
  // Minimal: text only, very subtle hover
  minimal: `
    bg-transparent
    text-[#d4c8e8] font-medium
    hover:text-[#00f5ff]
  `,
  // Outline: thin border, no fill
  outline: `
    bg-transparent
    text-[#d4c8e8] font-medium
    border border-white/10
    hover:border-[#bd00ff]/25 hover:text-white
  `,
  // Soft: subtle background
  soft: `
    bg-white/[0.03]
    text-[#d4c8e8] font-medium
    hover:bg-white/[0.07] hover:text-white
  `,
  // Primary: subtle gradient background (not harsh neon)
  primary: `
    bg-gradient-to-r from-[#bd00ff]/20 to-[#ff2d95]/15
    text-white font-medium
    border border-[#bd00ff]/20
    hover:from-[#bd00ff]/30 hover:to-[#ff2d95]/25
    hover:border-[#bd00ff]/30
  `,
  // Secondary: border emphasis
  secondary: `
    bg-transparent
    border border-[#00f5ff]/20
    text-[#d4c8e8] font-medium
    hover:bg-[#00f5ff]/5
    hover:border-[#00f5ff]/30
    hover:text-[#00f5ff]
  `,
  // Ghost: for nav items
  ghost: `
    bg-transparent
    text-[#d4c8e8] font-medium
    hover:text-[#00f5ff]
    hover:bg-white/[0.03]
  `,
};

const sizeStyles: Record<ButtonSize, string> = {
  sm: 'px-4 py-2 text-sm rounded-md',
  md: 'px-5 py-2.5 text-sm rounded-lg',
  lg: 'px-6 py-3 text-base rounded-lg',
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
      inline-flex items-center justify-center gap-2
      transition-all duration-200 ease-out
      focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#00f5ff]/50 focus-visible:ring-offset-2 focus-visible:ring-offset-[#0a0a0f]
      disabled:opacity-50 disabled:cursor-not-allowed
    `;

    const buttonContent = (
      <motion.button
        ref={ref}
        className={clsx(baseStyles, variantStyles[variant], sizeStyles[size], className)}
        whileHover={{ scale: 1.01 }}
        whileTap={{ scale: 0.99 }}
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
          whileHover={{ scale: 1.01 }}
          whileTap={{ scale: 0.99 }}
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
