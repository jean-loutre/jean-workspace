formatter = "plain"
exclude_files = { "third-party" }

stds.luaunit = {
	globals = { "LuaUnit" },
	read_globals = {
		"assert_equals",
		"assert_error_msg_contains",
		"assert_is_nil",
		"assert_not_nil",
	},
}

stds.nvim = {
	globals = { "_G" },
	read_globals = {
		vim = {
			fields = {
				"cmd",
				"inspect",
				"notify",
				"regex",
				"schedule",

				g = { read_only = false, other_fields = true },
				o = { read_only = false, other_fields = true },
				bo = { read_only = false, other_fields = true },

				api = {
					fields = {
						"nvim_buf_call",
						"nvim_buf_delete",
						"nvim_buf_get_name",
						"nvim_buf_is_valid",
						"nvim_chan_send",
						"nvim_command",
						"nvim_create_autocmd",
						"nvim_create_buf",
						"nvim_create_user_command",
						"nvim_del_user_command",
						"nvim_get_current_tabpage",
						"nvim_get_current_win",
						"nvim_get_option",
						"nvim_list_bufs",
						"nvim_open_win",
						"nvim_tabpage_get_win",
						"nvim_win_close",
						"nvim_win_is_valid",
						"nvim_win_set_buf",
						"nvim_win_get_buf",
					},
				},

				log = {
					fields = {
						levels = {
							fields = { "ERROR" },
						},
					},
				},

				lsp = {
					fields = {
						"start",
						"buf_attach_client",
					},
				},

				fn = {
					read_only = false,
					other_fields = true,
				},

				fs = {
					fields = {
						"basename",
						"getcwd",
						"dir",
						"parents",
						"regex",
					},
				},
			},
		},
	},
}

std = "min+nvim+luaunit"
