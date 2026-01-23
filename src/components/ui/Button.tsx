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
  // Primary: Bold orange accent - Neo-Brutalist hero button
  primary: `
    bg-[var(--accent-primary)]
    text-white font-bold uppercase tracking-wider
    border-4 border-[var(--brutalist-black)]
    shadow-[var(--shadow-brutal)]
    hover:shadow-[var(--shadow-brutal-sm)]
    hover:translate-x-[2px] hover:translate-y-[2px]
  `,
  // Secondary: Teal outline - readable accent
  secondary: `
    bg-transparent
    text-[var(--text-primary)] font-bold uppercase tracking-wider
    border-4 border-[var(--accent-secondary)]
    shadow-[4px_4px_0_0_var(--accent-secondary)]
    hover:shadow-[2px_2px_0_0_var(--accent-secondary)]
    hover:translate-x-[2px] hover:translate-y-[2px]
    hover:bg-[var(--accent-secondary)] hover:text-[#060606]
  `,
  // Outline: Subtle border, theme-aware
  outline: `
    bg-transparent
    text-[var(--text-secondary)] font-medium
    border-2 border-[var(--border-default)]
    hover:border-[var(--accent-primary)] hover:text-[var(--accent-primary)]
  `,
  // Ghost: Minimal hover effect
  ghost: `
    bg-transparent
    text-[var(--text-secondary)] font-medium
    hover:text-[var(--accent-primary)]
    hover:bg-[var(--surface-elevated)]
  `,
  // Minimal: Text only
  minimal: `
    bg-transparent
    text-[var(--text-secondary)] font-medium
    hover:text-[var(--accent-primary)]
  `,
  // Soft: Subtle background with glass effect
  soft: `
    bg-[var(--glass-bg)]
    backdrop-blur-sm
    text-[var(--text-secondary)] font-medium
    hover:text-[var(--text-primary)]
  `,
};

const sizeStyles: Record<ButtonSize, string> = {
  sm: 'px-4 py-2 text-sm',
  md: 'px-6 py-3 text-sm',
  lg: 'px-8 py-4 text-base',
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
      transition-all duration-150 ease-out
      focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--accent-primary)]/50 focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--surface-base)]
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
