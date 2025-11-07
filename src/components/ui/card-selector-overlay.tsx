"use client";

import React, { useState, useEffect } from "react";
import { cn } from "@/lib/utils";

export interface CardOption {
  id: string;
  name: string;
  description: string;
  icon: string;
  gradient: string;
}

interface SelectableCardProps {
  id: string;
  name: string;
  description: string;
  icon: string;
  gradient: string;
  isSelected: boolean;
  onClick: () => void;
  hoveredCardId?: string | null;
  onHover?: (cardId: string | null) => void;
}

function SelectableCard({
  id,
  name,
  description,
  icon,
  gradient,
  isSelected,
  onClick,
  hoveredCardId,
  onHover,
  inline = false
}: SelectableCardProps & { inline?: boolean }) {
  const isHovered = hoveredCardId === id;
  const isOtherCardHovered = hoveredCardId !== null && hoveredCardId !== id;

  const cardStyles = isSelected
    ? "border-primary/60 bg-card shadow-lg shadow-black/5 ring-4 ring-primary/10"
    : isHovered
    ? "border-primary/60 bg-card shadow-xl shadow-primary/10 ring-4 ring-primary/10"
    : isOtherCardHovered
    ? "border-border/60 bg-card opacity-60"
    : "border-border/60 bg-card hover:border-primary/60 hover:shadow-lg hover:shadow-black/5 hover:ring-4 hover:ring-primary/10";

  if (inline) {
    return (
      <div
        className={cn(
          "relative flex-shrink-0 w-[280px] sm:w-[320px] md:w-[360px] lg:w-[400px] p-6 sm:p-7 md:p-8 rounded-3xl border-2 cursor-pointer transition-all duration-500 ease-in-out group flex flex-col min-h-[320px]",
          cardStyles
        )}
        onClick={onClick}
        onMouseEnter={() => onHover?.(id)}
        onMouseLeave={() => onHover?.(null)}
      >
        {isSelected && (
          <div className="absolute -top-3 -right-3 w-7 h-7 bg-primary rounded-full flex items-center justify-center shadow-lg transition-all duration-300 ease-in-out z-10 ring-4 ring-background">
            <div className="w-2.5 h-2.5 bg-background rounded-full transition-all duration-300 ease-in-out"></div>
          </div>
        )}

        <div className="space-y-5 sm:space-y-6 relative z-10 flex flex-col h-full min-h-[320px]">
          <div className="relative flex-shrink-0">
            <div className={cn(
              "w-full h-24 sm:h-28 md:h-32 bg-gradient-to-br rounded-2xl flex items-center justify-center transition-all duration-300 ease-in-out shadow-md",
              gradient
            )}>
              <span className="text-4xl sm:text-5xl md:text-6xl transition-all duration-300 ease-in-out">{icon}</span>
            </div>
          </div>

          <div className="space-y-2 sm:space-y-3 flex-1 flex flex-col">
            <h3 className="font-bold text-lg sm:text-xl md:text-2xl text-foreground transition-all duration-300 ease-in-out">{name}</h3>
            <p className="text-sm sm:text-base text-muted-foreground leading-relaxed transition-all duration-300 ease-in-out flex-1">{description}</p>
            <div className="mt-4 pt-4 border-t border-border/30">
              <p className="text-xs text-muted-foreground/70 leading-relaxed">
                Click to select this option and continue with your project setup
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      className={cn(
        "relative p-8 md:p-10 lg:p-12 rounded-3xl border-2 cursor-pointer transition-all duration-500 ease-in-out group flex flex-col min-h-[400px] md:min-h-[480px] lg:min-h-[520px]",
        cardStyles
      )}
      onClick={onClick}
      onMouseEnter={() => onHover?.(id)}
      onMouseLeave={() => onHover?.(null)}
    >
      {isSelected && (
        <div className="absolute -top-3 -right-3 w-8 h-8 md:w-10 md:h-10 bg-primary rounded-full flex items-center justify-center shadow-xl transition-all duration-300 ease-in-out z-10 ring-4 ring-background">
          <div className="w-3 h-3 md:w-4 md:h-4 bg-background rounded-full transition-all duration-300 ease-in-out"></div>
        </div>
      )}

      <div className="space-y-6 md:space-y-8 lg:space-y-10 relative z-10 flex flex-col h-full">
        <div className="relative flex-shrink-0">
          <div className={cn(
            "w-full h-32 md:h-40 lg:h-48 bg-gradient-to-br rounded-2xl flex items-center justify-center mb-6 md:mb-8 transition-all duration-300 ease-in-out shadow-lg",
            gradient
          )}>
            <span className="text-5xl md:text-6xl lg:text-7xl xl:text-8xl transition-all duration-300 ease-in-out">{icon}</span>
          </div>
        </div>

        <div className="space-y-4 md:space-y-6 flex-1 flex flex-col">
          <h3 className="font-bold text-2xl md:text-3xl lg:text-4xl text-foreground transition-all duration-300 ease-in-out">{name}</h3>
          <p className="text-base md:text-lg lg:text-xl text-muted-foreground leading-relaxed transition-all duration-300 ease-in-out flex-1">{description}</p>
          <div className="mt-6 md:mt-8 pt-6 md:pt-8 border-t border-border/30">
            <p className="text-sm md:text-base text-muted-foreground/70 leading-relaxed">
              Click to select this option and continue with your project setup
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

interface CardSelectorOverlayProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (card: CardOption) => void;
  cards: CardOption[];
  title?: string;
  subtitle?: string;
  selectedCardId?: string | null;
  maxWidth?: string;
  gridCols?: "1" | "2" | "3" | "4";
  variant?: "overlay" | "inline";
  maxColumns?: number;
}

export function CardSelectorOverlay({
  isOpen,
  onClose,
  onSelect,
  cards,
  title,
  subtitle,
  selectedCardId = null,
  maxWidth,
  gridCols = "3",
  variant = "overlay",
  maxColumns
}: CardSelectorOverlayProps) {
  const [hoveredCardId, setHoveredCardId] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen && variant === "overlay") {
      document.body.style.overflow = "hidden";
    }

    return () => {
      if (variant === "overlay") {
        document.body.style.overflow = "";
      }
    };
  }, [isOpen, variant]);

  if (!isOpen) return null;

  const handleCardClick = (card: CardOption) => {
    onSelect(card);
  };

  if (variant === "inline") {
    return (
      <div className="w-full">
        {(title || subtitle) && (
          <div className="mb-6 transition-all duration-300 ease-in-out">
            {title && (
              <h2 className="text-2xl sm:text-3xl font-bold text-foreground transition-all duration-300 ease-in-out mb-2">{title}</h2>
            )}
            {subtitle && (
              <p className="text-sm sm:text-base text-muted-foreground transition-all duration-300 ease-in-out">{subtitle}</p>
            )}
          </div>
        )}

        <div className="overflow-x-auto overflow-y-visible scrollbar-hide pb-4 -mx-4 sm:-mx-2 px-4 sm:px-2">
          <div className="flex gap-4 sm:gap-6 min-w-max">
            {cards.map((card) => (
              <SelectableCard
                key={card.id}
                id={card.id}
                name={card.name}
                description={card.description}
                icon={card.icon}
                gradient={card.gradient}
                isSelected={selectedCardId === card.id}
                onClick={() => handleCardClick(card)}
                hoveredCardId={hoveredCardId}
                onHover={setHoveredCardId}
                inline={true}
              />
            ))}
          </div>
        </div>
      </div>
    );
  }

  const effectiveMaxColumns = maxColumns || parseInt(gridCols);
  
  const getResponsiveGridClass = () => {
    if (maxColumns) {
      const cols = Math.min(effectiveMaxColumns, cards.length);
      if (cols === 1) return "grid-cols-1";
      if (cols === 2) return "grid-cols-1 sm:grid-cols-2";
      if (cols === 3) return "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3";
      if (cols === 4) return "grid-cols-1 sm:grid-cols-2 xl:grid-cols-4";
      if (cols === 5) return "grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5";
      if (cols >= 6) return "grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6";
    }
    return {
      "1": "grid-cols-1",
      "2": "grid-cols-1 md:grid-cols-2",
      "3": "grid-cols-1 md:grid-cols-2 lg:grid-cols-3",
      "4": "grid-cols-1 sm:grid-cols-2 xl:grid-cols-4"
    }[gridCols];
  };

  const gridClass = getResponsiveGridClass();

  return (
    <div
      className="fixed left-0 md:left-16 right-0 top-0 bottom-0 z-[70] bg-background flex items-center justify-center p-4 md:p-6 lg:p-8 transition-all duration-300 ease-in-out"
    >
      <div className="w-full h-full md:h-auto max-h-[90vh] flex flex-col items-center justify-start pt-6 md:pt-8 lg:pt-10 transition-all duration-300 ease-in-out overflow-y-auto scrollbar-hide">
        {(title || subtitle) && (
          <div className="mb-8 sm:mb-12 md:mb-16 max-w-6xl w-full px-6 md:px-8 lg:px-12 flex-shrink-0 pt-4 md:pt-6">
            <div className="flex items-center gap-4 md:gap-6 mb-4 md:mb-6">
              <div className="w-2 h-12 sm:h-16 md:h-20 bg-gradient-to-b from-blue-400 via-purple-500 to-purple-600 rounded-full"></div>
              {title && (
                <h2 className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl xl:text-8xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 dark:from-blue-400 dark:via-purple-500 dark:to-pink-500 bg-clip-text text-transparent leading-tight">
                  {title}
                </h2>
              )}
            </div>
            {subtitle && (
              <div className="pl-6 md:pl-8 lg:pl-10">
                <p className="text-lg sm:text-xl md:text-2xl lg:text-3xl text-muted-foreground/90 leading-relaxed transition-all duration-300 ease-in-out">
                  {subtitle}
                </p>
              </div>
            )}
          </div>
        )}

        <div className={cn("w-full px-6 md:px-8 lg:px-12 pb-6 md:pb-8 lg:pb-12", maxWidth || "max-w-[1920px]")}>
          <div className={cn("grid gap-6 sm:gap-8 md:gap-10 lg:gap-12", gridClass)}>
            {cards.map((card) => (
              <SelectableCard
                key={card.id}
                id={card.id}
                name={card.name}
                description={card.description}
                icon={card.icon}
                gradient={card.gradient}
                isSelected={selectedCardId === card.id}
                onClick={() => handleCardClick(card)}
                hoveredCardId={hoveredCardId}
                onHover={setHoveredCardId}
                inline={false}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

