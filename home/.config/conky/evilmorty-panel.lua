require 'cairo'

local panel = {
    x = 9,
    y = 8,
    w = 230,
    h = 538,
    r = 10,
}

local colors = {
    bg = {0.015, 0.035, 0.018, 0.68},
    bg_glow = {0.18, 0.55, 0.13, 0.08},
    border = {0.36, 0.95, 0.28, 0.34},
    track = {0.16, 0.30, 0.14, 0.55},
    fill = {0.48, 0.96, 0.34, 0.92},
    fill_dim = {0.28, 0.70, 0.22, 0.78},
    divider = {0.23, 0.46, 0.20, 0.46},
}

local function rgba(cr, c)
    cairo_set_source_rgba(cr, c[1], c[2], c[3], c[4])
end

local function rounded_rect(cr, x, y, w, h, r)
    cairo_new_sub_path(cr)
    cairo_arc(cr, x + w - r, y + r, r, -math.pi / 2, 0)
    cairo_arc(cr, x + w - r, y + h - r, r, 0, math.pi / 2)
    cairo_arc(cr, x + r, y + h - r, r, math.pi / 2, math.pi)
    cairo_arc(cr, x + r, y + r, r, math.pi, math.pi * 1.5)
    cairo_close_path(cr)
end

local function pct(expr)
    local n = tonumber(conky_parse(expr)) or 0
    if n < 0 then return 0 end
    if n > 100 then return 100 end
    return n
end

local function bar(cr, x, y, w, h, value)
    rounded_rect(cr, x, y, w, h, 1.5)
    rgba(cr, colors.track)
    cairo_fill_preserve(cr)
    cairo_set_line_width(cr, 1)
    rgba(cr, colors.border)
    cairo_stroke(cr)

    local fill_w = math.max(3, (w - 2) * (value / 100))
    rounded_rect(cr, x + 1, y + 1, fill_w, h - 2, 1.5)
    rgba(cr, value > 65 and colors.fill or colors.fill_dim)
    cairo_fill(cr)
end

local function line(cr, x1, y, x2)
    cairo_move_to(cr, x1, y)
    cairo_line_to(cr, x2, y)
    cairo_set_line_width(cr, 1)
    rgba(cr, colors.divider)
    cairo_stroke(cr)
end

function conky_main()
    if conky_window == nil then
        return
    end

    local surface = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )
    local cr = cairo_create(surface)

    rounded_rect(cr, panel.x, panel.y, panel.w, panel.h, panel.r)
    rgba(cr, colors.bg)
    cairo_fill_preserve(cr)
    cairo_set_line_width(cr, 1)
    rgba(cr, colors.border)
    cairo_stroke(cr)

    rounded_rect(cr, panel.x + 1, panel.y + 1, panel.w - 2, panel.h - 2, panel.r - 1)
    rgba(cr, colors.bg_glow)
    cairo_fill(cr)

    bar(cr, 34, 122, 184, 13, pct('${cpu cpu0}'))
    bar(cr, 34, 205, 184, 13, pct('${memperc}'))
    bar(cr, 34, 288, 184, 13, pct('${fs_used_perc /}'))
    line(cr, 31, 407, 217)

    cairo_destroy(cr)
    cairo_surface_destroy(surface)
end
